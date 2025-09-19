import os, strutils, re, sequtils, sets, algorithm

proc usage(): void =
  echo "Uso: find_hosts <ficheiro>"
  quit(1)

if paramCount() != 1:
  usage()

let path = paramStr(1)
if not fileExists(path):
  echo "Ficheiro não encontrado: ", path
  quit(1)

# lê ficheiro (função readFile aceita binários — Nim strings podem conter bytes)
let data = readFile(path)

# Regexes (ajusta conforme quiseres)
# IPv4 (validação comum: cada octeto 0-255)
let ipv4_pat = re(r"\b(?:(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?!$)|$)){4}\b", flags = {re_study})

# IPv6 (captura formas comuns, incluindo compressão :: — expressão relativamente extensa)
# Fonte de referência / exemplos: regex101 / colecções de regex para IPv6. Ajusta se precisares de cenários muito específicos.
let ipv6_pat = re(r"\b(?:(?:[A-Fa-f0-9]{1,4}:){7}[A-Fa-f0-9]{1,4}|(?:[A-Fa-f0-9]{1,4}:){1,7}:|:(?::[A-Fa-f0-9]{1,4}){1,7}|(?:[A-Fa-f0-9]{1,4}:){1,6}:[A-Fa-f0-9]{1,4}|(?:[A-Fa-f0-9]{1,4}:){1,5}(?::[A-Fa-f0-9]{1,4}){1,2}|(?:[A-Fa-f0-9]{1,4}:){1,4}(?::[A-Fa-f0-9]{1,4}){1,3}|(?:[A-Fa-f0-9]{1,4}:){1,3}(?::[A-Fa-f0-9]{1,4}){1,4}|(?:[A-Fa-f0-9]{1,4}:){1,2}(?::[A-Fa-f0-9]{1,4}){1,5})\b", flags = {re_study})

# Domínios: labels até 63 chars, não começar/terminar com '-', tld mínimo 2 chars
# Baseado nas regras de nomes de domínio (RFCs) — simplificação prática para extracção em texto livre.
#let domain_pat = re(r"\b(?:[A-Za-z0-9](?:[A-Za-z0-9\-]{0,61}[A-Za-z0-9])?\.)+[A-Za-z]{2,63}\b", flags = {re_study, re_ignore_case})

# Url regex
let url_pat = re(r"\b(?:(?:https?|ftp):\/\/)(?:[A-Za-z0-9\-_]+\.)+[A-Za-z]{2,63}(?::\d{1,5})?(?:\/[^\s]*)?\b", flags = {re_study, re_ignore_case})



# Utilitário para correr findAll e retornar seq[string]
proc findAllMatches(pat: Regex, txt: string): seq[string] =
  result = @[]
  for m in findAll(txt, pat):
    # findAll devolve as strings correspondentes
    if m.len > 0:
      result.add(m)

# Faz as buscas
let ipv4s: seq[string] = findAllMatches(ipv4_pat, data)
let ipv6s: seq[string] = findAllMatches(ipv6_pat, data)
let urls: seq[string] = findAllMatches(url_pat, data)

# Normaliza e remove duplicados
proc uniqSorted(s: seq[string]): seq[string] =
  # strip de espaços em cada elemento
  var tmp: seq[string] = @[]
  for x in s:
    let y = x.strip()
    if y.len > 0:
      tmp.add(y)
  # converter para set para remover duplicados
  var st: HashSet[string] = initHashSet[string]()
  for y in tmp:
    st.incl(y)
  result = @[] # seq para resultado final
  for y in st:
    result.add(y)
  result.sort() # fazer sort para saída ordenada

let ipv4u: seq[string] = uniqSorted(ipv4s)
let ipv6u: seq[string] = uniqSorted(ipv6s)
let urlu: seq[string]  = uniqSorted(urls)

# Print resultados
if ipv4u.len == 0 and ipv6u.len == 0 and urlu.len == 0:
  echo "Nenhum IP ou domínio encontrado."
else:
  if ipv4u.len > 0:
    echo "\nIPv4 encontrados (", ipv4u.len, "):"
    for ip in ipv4u: echo "  ", ip
  if ipv6u.len > 0:
    echo "\nIPv6 encontrados (", ipv6u.len, "):"
    for ip in ipv6u: echo "  ", ip
  if urlu.len > 0:
    echo "\nUrl's encontrados (", urlu.len, "):"
    for d in urlu: echo "  ", d

