import os, htmlparser, strutils, strtabs, strformat
import httpclient
import xmltree except escape
import re

type
  ParseException* = object of Exception
  XmlNodeException* = object of ParseException

var
  incremental = 2
  karaxHtml = ""

template to(t: string) {.dirty.} =
  var localIndent = incremental

  # base tag
  karaxHtml.add indent("\n" &  t &  "(", localIndent)
  # tag attributes
  var attr: seq[string]
  if node.attrs != nil:
    for name,value in node.attrs.pairs:
      attr.add &"{name}=\"{value}\""
  # tag suffix
  var suffix = if node.len != 0 :"):" else: ")"
  karaxHtml.add attr.join(",") & suffix

  # Traverse next level of children
  for i in 0..node.len-1:
    # If node is an element with 0 or more children
    if node[i].kind == xnElement:
        incremental.inc(2)
        # Recursively call getXmlNode on child
        parseXmlNode node[i]
        # Reset incremental
        incremental = localIndent
    elif node[i].kind == xnText : # If text element
      var text = node[i].innerText
      if text.strip() == "": continue
      if {'\n','\"','\\'} in text:
        if text == "\n": continue
        text = text.escape()
        if text.find(re"\\x0A") > 0:
          text = text.replace(re"\\x0A\s?"," ")
        karaxHtml.add indent("\ntext " & text , incremental+2)
      else:
        karaxHtml.add indent("\ntext \"" & text & "\"" , incremental+2)

proc parseXmlNode(node: var XmlNode) =
  case node.tag
  of "a": to "a"
  of "abbr": to "abbr"
  of "acronym": to "acronym"
  of "address": to "address"
  of "applet": to "applet"
  of "area": to "area"
  of "article": to "article"
  of "aside": to "aside"
  of "audio": to "audio"
  of "b": to "bold"
  of "base": to "base"
  of "basefont": to "basefont"
  of "bdi": to "bdi"
  of "bdo": to "bdo"
  of "big": to "big"
  of "blockquote": to "blockquote"
  of "body": to "body"
  of "br": to "br"
  of "button": to "button"
  of "canvas": to "canvas"
  of "caption": to "caption"
  of "center": to "center"
  of "cite": to "cite"
  of "code": to "code"
  of "col": to "col"
  of "colgroup": to "colgroup"
  of "command": to "command"
  of "datalist": to "datalist"
  of "dd": to "dd"
  of "del": to "del"
  of "details": to "details"
  of "dfn": to "dfn"
  of "dialog": to "dialog"
  of "div": to "tdiv"
  of "dir": to "dir"
  of "dl": to "dl"
  of "dt": to "dt"
  of "em": to "em"
  of "embed": to "embed"
  of "fieldset": to "fieldset"
  of "figcaption": to "figcaption"
  of "figure": to "figure"
  of "font": to "font"
  of "footer": to "footer"
  of "form": to "form"
  of "frame": to "frame"
  of "frameset": to "frameset"
  of "h1": to "h1"
  of "h2": to "h2"
  of "h3": to "h3"
  of "h4": to "h4"
  of "h5": to "h5"
  of "h6": to "h6"
  of "head": to "head"
  of "header": to "header"
  of "hgroup": to "hgroup"
  of "html": to "html"
  of "hr": to "hr"
  of "i": to "i"
  of "iframe": to "iframe"
  of "img": to "img"
  of "input": to "input"
  of "ins": to "ins"
  of "isindex": to "isindex"
  of "kbd": to "kbd"
  of "keygen": to "keygen"
  of "label": to "label"
  of "legend": to "legend"
  of "li": to "li"
  of "link": discard
  of "map": to "map"
  of "mark": to "mark"
  of "menu": to "menu"
  of "meta": to "meta"
  of "meter": to "meter"
  of "nav": to "nav"
  of "nobr": to "nobr"
  of "noframes": to "noframes"
  of "noscript": to "noscript"
  of "object": to "object"
  of "ol": to "ol"
  of "optgroup": to "optgroup"
  of "option": to "option"
  of "output": to "output"
  of "p": to "p"
  of "param": to "param"
  of "pre": to "pre"
  of "progress": to "progress"
  of "q": to "q"
  of "rp": to "rp"
  of "rt": to "rt"
  of "ruby": to "ruby"
  of "s": to "s"
  of "samp": to "samp"
  of "script": discard
  of "section": to "section"
  of "select": to "select"
  of "small": to "small"
  of "source": to "source"
  of "span": to "span"
  of "strike": to "strike"
  of "strong": to "strong"
  of "style": discard
  of "sub": to "sub"
  of "summary": to "summary"
  of "sup": to "sup"
  of "table": to "table"
  of "tbody": to "tbody"
  of "td": to "td"
  of "textarea": to "textarea"
  of "tfoot": to "tfoot"
  of "th": to "th"
  of "thead": to "thead"
  of "time": to "time"
  of "title": to "title"
  of "tr": to "tr"
  of "track": to "track"
  of "tt": to "tt"
  of "u": to "u"
  of "ul": to "ul"
  of "var": to "var"
  of "video": to "video"
  of "wbr": to "wbr"
  else:
    raise newException(XmlNodeException, &"error processing {node.tag}")

proc html2Karax*(raw: string, tag: string = "html"): string =
  let html = raw.parseHtml()
  var body = html.findAll(tag)[0]
  parseXmlNode(body)
  karaxHtml

when isMainModule:
  if paramCount() == 0:
    quit("missing arg")

  let client = newHttpClient()
  let resp = client.get(paramStr(1))

  echo html2Karax(resp.body)