/* GameKit Factory — original sliding puzzle rules. No dependencies, no network. */
(function (root, factory) {
  "use strict";
  const api = factory();
  if (typeof module === "object" && module.exports) module.exports = api;
  root.GameKitPuzzle = api;
})(typeof globalThis === "object" ? globalThis : this, function () {
  "use strict";
  const width = 4, count = 16;
  function goal() { return Array.from({length: count}, (_, i) => (i + 1) % count); }
  function valid(board) {
    return Array.isArray(board) && board.length === count &&
      board.every(Number.isInteger) && [...board].sort((a,b)=>a-b).every((x,i)=>x===i);
  }
  function neighbors(i) {
    if (!Number.isInteger(i) || i < 0 || i >= count) return [];
    return [i >= width ? i-width : -1, i < count-width ? i+width : -1,
      i%width ? i-1 : -1, i%width < width-1 ? i+1 : -1].filter(n=>n>=0);
  }
  function solved(board) { return valid(board) && board.every((x,i)=>x===(i+1)%count); }
  function solvable(board) {
    if (!valid(board)) return false;
    let inversions = 0;
    for(let i=0;i<count;i++) for(let j=i+1;j<count;j++)
      if(board[i] && board[j] && board[i]>board[j]) inversions++;
    const blankRowFromBottom = width - Math.floor(board.indexOf(0)/width);
    return (inversions + blankRowFromBottom) % 2 === 1;
  }
  function rng(seed) {
    let s = seed >>> 0;
    return function() {
      s = (s + 0x6D2B79F5) >>> 0;
      let t = Math.imul(s ^ (s >>> 15), 1 | s);
      t ^= t + Math.imul(t ^ (t >>> 7), 61 | t);
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }
  function shuffle(seed, steps=180) {
    const b = goal(), random=rng(seed), total=Math.max(1, Math.min(5000,Math.floor(steps)));
    let previous=-1;
    for(let k=0;k<total;k++) {
      const blank=b.indexOf(0), candidates=neighbors(blank).filter(n=>n!==previous);
      const options=candidates.length?candidates:neighbors(blank);
      const selected=options[Math.floor(random()*options.length)];
      [b[blank],b[selected]]=[b[selected],b[blank]];
      previous=blank;
    }
    if(solved(b)) { const z=b.indexOf(0), n=neighbors(z)[0]; [b[z],b[n]]=[b[n],b[z]]; }
    return b;
  }
  function move(board, index) {
    if (!valid(board) || !neighbors(board.indexOf(0)).includes(index)) return null;
    const b=board.slice(), blank=b.indexOf(0);
    [b[blank],b[index]]=[b[index],b[blank]];
    return b;
  }
  function dayKey(now=new Date()) {
    return [now.getFullYear(),String(now.getMonth()+1).padStart(2,"0"),
      String(now.getDate()).padStart(2,"0")].join("-");
  }
  function dailySeed(key) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(key)) throw new Error("Invalid date key");
    return Number(key.replace(/-/g,""));
  }
  return Object.freeze({width,goal,valid,neighbors,solved,solvable,shuffle,move,dayKey,dailySeed});
});
