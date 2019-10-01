let won = false
let x   = null
let o   = null

function check() {
  const tds = document.getElementsByTagName('TD')
  const patterns = [
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],

    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],

    [0, 4, 8],
    [2, 4, 6]
  ]


  for(const pattern of patterns) {
    let i = pattern[0]
    let j = pattern[1]
    let k = pattern[2]

    if(!tds[i].hasChildNodes()) continue
    if(!tds[j].hasChildNodes()) continue
    if(!tds[k].hasChildNodes()) continue

    if(!tds[i].isEqualNode(tds[j])) continue
    if(!tds[i].isEqualNode(tds[k])) continue

    let img = tds[i].children[0]
    for(const td of tds) {
      while(td.hasChildNodes()) {
        td.removeChild(td.children[0])
      }

      td.appendChild(img.cloneNode())
    }

    won = true
    return

  }
}

function clear() {
  const tds = document.getElementsByTagName('TD')
  for(const td of tds) {
    while(td.hasChildNodes()) {
      td.removeChild(td.children[0])
    }
  }
}

function ai() {
  let tds = document.getElementsByTagName('TD')
  tds = Array.from(tds).filter(td => !td.hasChildNodes())

  if(tds.length > 0) {
    let td = tds[Math.floor(Math.random() * tds.length)]
    td.appendChild(o.cloneNode())
    check()
  }
}


window.onload = function() {
  x = document.getElementById('x')
  o = document.getElementById('o')

  let table = document.getElementById('board')
  table.addEventListener('click', event => {
    if(!won){
      if(event.target.tagName == 'TD') {
        if(!event.target.hasChildNodes()) {
          event.target.appendChild(x.cloneNode())
          check()
          ai()
        }
      }
    }
    else {
      won = false
      clear()
    }
  })
}
