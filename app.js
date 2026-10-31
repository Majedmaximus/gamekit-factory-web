"use strict";
const puzzle=globalThis.GameKitPuzzle;
if (!puzzle) throw new Error("Puzzle engine not loaded");
const SAVE_KEY="gamekit-slide15-daily-v2";
const COPY={
  en:{title:"Slide 15",subtitle:"A fresh puzzle every day. No login or tracking.",daily:"Daily puzzle",newGame:"New game",restart:"Restart",undo:"Undo",language:"العربية",share:"Copy result",instructions:"Tap a numbered tile beside the empty space, or use your arrow keys.",moves:n=>`Moves: ${n}`,won:n=>`Well done! Solved in ${n} moves.`,today:"Today's challenge",random:"Free play",saved:"Progress is saved on this device.",best:n=>`Best daily score: ${n} moves`},
  ar:{title:"لغز ١٥",subtitle:"لغز جديد كل يوم، دون حساب أو تتبع.",daily:"التحدي اليومي",newGame:"لعبة جديدة",restart:"إعادة",undo:"تراجع",language:"English",share:"نسخ النتيجة",instructions:"المس قطعة بجانب الفراغ، أو استخدم الأسهم في لوحة المفاتيح.",moves:n=>`الحركات: ${n}`,won:n=>`أحسنت! أكملت اللغز في ${n} حركة.`,today:"تحدي اليوم",random:"لعب حر",saved:"يُحفظ التقدم على هذا الجهاز.",best:n=>`أفضل نتيجة يومية: ${n} حركة`}
};
const $=id=>document.getElementById(id);
let lang=(navigator.language||"en").toLowerCase().startsWith("ar")?"ar":"en";
let board=[],initial=[],moves=0,history=[],mode="daily",dailyKey=puzzle.dayKey(),best=null;
function store(value) {try{localStorage.setItem(SAVE_KEY,JSON.stringify(value));}catch(_error){}}
function read() {try{return JSON.parse(localStorage.getItem(SAVE_KEY)||"null");}catch(_error){return null;}}
function snapshot(){
  if(mode!=="daily")return;
  store({key:dailyKey,board,moves,initial,history:history.slice(-500),best});
}
function startDaily(){
  mode="daily"; dailyKey=puzzle.dayKey();moves=0;history=[];best=null;
  const existing=read();
  if(existing && existing.key===dailyKey && puzzle.valid(existing.board) &&
    puzzle.valid(existing.initial) && puzzle.solvable(existing.board) &&
    Number.isSafeInteger(existing.moves) && existing.moves>=0){
    board=existing.board.slice();initial=existing.initial.slice();moves=existing.moves;
    best=(Number.isSafeInteger(existing.best)&&existing.best>=0)?existing.best:null;
    history=Array.isArray(existing.history)?existing.history.filter(puzzle.valid).slice(-500):[];
  }else{
    board=puzzle.shuffle(puzzle.dailySeed(dailyKey));initial=board.slice();snapshot();
  }
  render();
}
function startNew(){
  mode="random";moves=0;history=[];best=null;
  const seed=(Date.now()^Math.floor(Math.random()*4294967296))>>>0;
  board=puzzle.shuffle(seed);initial=board.slice();render();
}
function restart(){board=initial.slice();moves=0;history=[];snapshot();render();}
function undo(){
  if(!history.length)return;
  board=history.pop();moves=Math.max(0,moves-1);snapshot();render();
}
function play(index){
  if(puzzle.solved(board)) return;
  const next=puzzle.move(board,index);
  if(!next)return;
  history.push(board.slice());if(history.length>500)history.shift();
  board=next;moves++;
  if(puzzle.solved(board)&&mode==="daily"&&(best===null||moves<best))best=moves;
  snapshot();render();
}
function translated(key){return COPY[lang][key];}
function render(){
  document.documentElement.lang=lang;
  document.documentElement.dir=lang==="ar"?"rtl":"ltr";
  document.title=translated("title")+" • GameKit Factory";
  $("title").textContent=translated("title");
  $("subtitle").textContent=translated("subtitle");
  $("daily").textContent=translated("daily");
  $("new").textContent=translated("newGame");
  $("restart").textContent=translated("restart");
  $("undo").textContent=translated("undo");
  $("language").textContent=translated("language");
  $("share").textContent=translated("share");
  $("instructions").textContent=translated("instructions");
  $("mode").textContent=mode==="daily"?translated("today")+" · "+dailyKey:translated("random");
  $("saved").textContent=translated("saved");
  const won=puzzle.solved(board);
  $("status").textContent=won?translated("won")(moves):translated("moves")(moves);
  $("best").textContent=best!==null?translated("best")(best):"";
  $("share").hidden=!won;
  $("undo").disabled=!history.length;
  const container=$("board");container.replaceChildren();
  const possible=puzzle.neighbors(board.indexOf(0));
  for(let i=0;i<16;i++){
    const tile=document.createElement("button");
    tile.type="button";tile.className="tile"+(board[i]===0?" empty":"");
    tile.textContent=board[i]===0?"":String(board[i]);
    tile.disabled=won||board[i]===0||!possible.includes(i);
    tile.setAttribute("aria-label",board[i]===0?"Empty square":`Tile ${board[i]}`);
    tile.addEventListener("click",()=>play(i));container.appendChild(tile);
  }
}
$("daily").addEventListener("click",startDaily);
$("new").addEventListener("click",startNew);
$("restart").addEventListener("click",restart);
$("undo").addEventListener("click",undo);
$("language").addEventListener("click",()=>{lang=lang==="ar"?"en":"ar";render();});
$("share").addEventListener("click",async()=>{
 const summary=`Slide 15 | ${mode==="daily"?dailyKey:"free play"} | ${moves} moves`;
 try{if(navigator.clipboard&&navigator.clipboard.writeText)await navigator.clipboard.writeText(summary);
 else window.prompt("Copy result",summary);}catch(_error){window.prompt("Copy result",summary);}
});
document.addEventListener("keydown",event=>{
 if(["ArrowUp","ArrowDown","ArrowLeft","ArrowRight"].includes(event.key)){
   const blank=board.indexOf(0), offsets={ArrowUp:-4,ArrowDown:4,ArrowLeft:-1,ArrowRight:1};
   const target=blank+offsets[event.key];
   if(puzzle.neighbors(blank).includes(target)){event.preventDefault();play(target);}
 }
});
if("serviceWorker" in navigator && location.protocol!=="file:"){
 window.addEventListener("load",()=>navigator.serviceWorker.register("./sw.js").catch(()=>{}));
}
startDaily();
