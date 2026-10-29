// 여울 웹 데모: 사건을 더하면 간격이 실제로 흐른 시간만큼 벌어진다.
// 규칙은 앱과 같다 (Shared/Views/TimelineTrackView.swift 의 TrackMetrics · TrackScale).
// 페이지에 맞게 모든 길이를 SCALE 배로 줄여 그린다. 비율과 접히는 시점은 앱과 똑같다.
(() => {
  const root = document.getElementById("demo");
  if (!root) return;
  const T = JSON.parse(root.dataset.text);
  const lang = document.documentElement.lang || "en";

  const M = { minGap: 26, maxGap: 560, idealTotal: 2400, labelMin: 18 };
  const SCALE = 0.25, ROW = 30, MAX = 6;
  const STEPS = { "3d": [0, 0, 3], "5d": [0, 0, 5], "1m": [0, 1, 0], "2y4m": [2, 4, 0] };
  const START = new Date(2024, 2, 5);
  const DAY = 86400000;

  const add = (d, [y, m, dd]) => new Date(d.getFullYear() + y, d.getMonth() + m, d.getDate() + dd);
  const fmt = new Intl.DateTimeFormat(lang, { year: "numeric", month: "short", day: "numeric" });

  let events;   // [{date, gap}] gap 은 바로 앞 사건과의 간격 키
  // 처음 모습: 사흘 뒤, 다시 닷새 뒤. 두 간격이 3대 5로 보인다.
  const reset = () => {
    const a = add(START, STEPS["3d"]);
    events = [{ date: START }, { date: a, gap: "3d" }, { date: add(a, STEPS["5d"]), gap: "5d" }];
  };
  reset();

  root.innerHTML = `
    <div class="demo-stage"><div class="yw-track" aria-hidden="true"></div>
      <ol class="yw-list"></ol></div>
    <div class="demo-controls">
      <div class="demo-chips">
        ${Object.keys(STEPS).map(k => `<button type="button" class="chip" data-step="${k}">+ ${T.steps[k]}</button>`).join("")}
      </div>
      <button type="button" class="yw-reset">${T.reset}</button>
      <p class="yw-full muted small" aria-live="polite"></p>
      <p class="muted small demo-note">${T.note}</p>
    </div>`;

  const $ = s => root.querySelector(s);
  const track = $(".yw-track"), list = $(".yw-list"), full = $(".yw-full");

  // TrackScale: 전체 기간에 하나의 pt/일 배율. 너무 짧은 간격은 minGap, 너무 긴 간격은 maxGap 에서 잘리고 점선이 된다.
  function layout() {
    const span = Math.max(1, (events[events.length - 1].date - events[0].date) / DAY);
    const perDay = Math.min(Math.max(M.idealTotal / span, 0.25), 40);
    let y = 0;
    return events.map((e, i) => {
      if (i === 0) return { y, e };
      const raw = ((e.date - events[i - 1].date) / DAY) * perDay;
      const h = Math.min(Math.max(raw, M.minGap), M.maxGap);
      const gap = { top: y + ROW / 2, height: h * SCALE + ROW, folded: raw > M.maxGap, label: h >= M.labelMin };
      y += h * SCALE + ROW;
      return { y, e, gap };
    });
  }

  function render(fresh) {
    const rows = layout();
    track.style.height = `${rows[rows.length - 1].y + ROW}px`;
    track.innerHTML = rows.map(({ y, e, gap }, i) => `
      ${gap ? `<i class="yw-line${gap.folded ? " folded" : ""}" style="top:${gap.top}px;height:${gap.height}px"></i>
        ${gap.label ? `<span class="yw-gap" style="top:${gap.top + gap.height / 2}px">${T.gaps[e.gap]}</span>` : ""}` : ""}
      <span class="yw-node${fresh && i === rows.length - 1 ? " fresh" : ""}" style="top:${y}px">
        <b></b>${fmt.format(e.date)}</span>`).join("");
    list.innerHTML = rows.map(({ e }) => `<li>${fmt.format(e.date)}${e.gap ? `, ${T.gaps[e.gap]}` : ""}</li>`).join("");
    const done = events.length >= MAX;
    root.querySelectorAll("[data-step]").forEach(b => {
      b.disabled = done;
      b.classList.toggle("hint", !done && !root.dataset.used && b.dataset.step === "2y4m");
    });
    full.textContent = done ? T.full : "";
  }

  root.addEventListener("click", ev => {
    const step = ev.target.closest("[data-step]");
    if (step && events.length < MAX) {
      root.dataset.used = "1";
      const last = events[events.length - 1].date;
      events.push({ date: add(last, STEPS[step.dataset.step]), gap: step.dataset.step });
      render(true);
    } else if (ev.target.closest(".yw-reset")) {
      reset();
      render(false);
    }
  });

  render(false);
})();
