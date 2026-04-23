import { useState } from "react";
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip,
  ResponsiveContainer, ReferenceLine, Area, AreaChart
} from "recharts";

const DATA = [
  { year: "2015", re_sph: -1.75, le_sph: -2.00, re_cyl: -0.50, le_cyl: -0.75, re_axis: 90,  le_axis: 85,  re_add: null, le_add: null, practice: "Specsavers, Manchester" },
  { year: "2016", re_sph: -2.00, le_sph: -2.25, re_cyl: -0.50, le_cyl: -0.75, re_axis: 90,  le_axis: 85,  re_add: null, le_add: null, practice: "Specsavers, Manchester" },
  { year: "2017", re_sph: -2.00, le_sph: -2.25, re_cyl: -0.50, le_cyl: -0.75, re_axis: 92,  le_axis: 87,  re_add: null, le_add: null, practice: "Vision Express, Leeds" },
  { year: "2018", re_sph: -2.25, le_sph: -2.50, re_cyl: -0.50, le_cyl: -0.75, re_axis: 90,  le_axis: 85,  re_add: null, le_add: null, practice: "Vision Express, Leeds" },
  { year: "2019", re_sph: -2.25, le_sph: -2.50, re_cyl: -0.75, le_cyl: -1.00, re_axis: 90,  le_axis: 85,  re_add: null, le_add: null, practice: "Vision Express, Leeds" },
  { year: "2020", re_sph: -2.25, le_sph: -2.75, re_cyl: -0.75, le_cyl: -1.00, re_axis: 92,  le_axis: 85,  re_add: null, le_add: null, practice: "Independent, York" },
  { year: "2021", re_sph: -2.50, le_sph: -2.75, re_cyl: -0.75, le_cyl: -1.00, re_axis: 90,  le_axis: 87,  re_add: 0.75, le_add: 0.75, practice: "Independent, York" },
  { year: "2022", re_sph: -2.50, le_sph: -3.00, re_cyl: -0.75, le_cyl: -1.00, re_axis: 90,  le_axis: 85,  re_add: 1.00, le_add: 1.00, practice: "Independent, York" },
  { year: "2023", re_sph: -2.50, le_sph: -3.00, re_cyl: -0.75, le_cyl: -1.25, re_axis: 90,  le_axis: 85,  re_add: 1.25, le_add: 1.25, practice: "Independent, York" },
  { year: "2024", re_sph: -2.50, le_sph: -3.00, re_cyl: -0.75, le_cyl: -1.25, re_axis: 92,  le_axis: 87,  re_add: 1.50, le_add: 1.50, practice: "Independent, York" },
];

const METRICS = [
  {
    key: "sph", label: "Sphere", unit: "DS",
    desc: "Main correction strength",
    reKey: "re_sph", leKey: "le_sph",
    domain: [-4, 0], tickCount: 5,
    note: (d) => {
      const delta = d[d.length-1].re_sph - d[0].re_sph;
      return delta < -0.5 ? `Right eye has progressed ${Math.abs(delta).toFixed(2)} DS over 10 years` : "Prescription has remained broadly stable";
    }
  },
  {
    key: "cyl", label: "Cylinder", unit: "DC",
    desc: "Astigmatism correction",
    reKey: "re_cyl", leKey: "le_cyl",
    domain: [-2, 0], tickCount: 5,
    note: () => "Left eye astigmatism has gradually increased since 2019"
  },
  {
    key: "axis", label: "Axis", unit: "°",
    desc: "Astigmatism direction",
    reKey: "re_axis", leKey: "le_axis",
    domain: [75, 100], tickCount: 6,
    note: () => "Axis has remained consistent — astigmatism orientation is stable"
  },
  {
    key: "add", label: "Addition", unit: "DS",
    desc: "Reading addition (presbyopia)",
    reKey: "re_add", leKey: "le_add",
    domain: [0, 2], tickCount: 5,
    note: () => "ADD appeared in 2021 and has increased by +0.25 each year — typical presbyopia progression"
  },
];

const RE_COLOR = "#7dd3fc";
const LE_COLOR = "#fda4af";
const GRID_COLOR = "#1e2535";
const AXIS_COLOR = "#3d4663";

function formatVal(val, unit) {
  if (val === null || val === undefined) return "—";
  const prefix = (unit === "DS" || unit === "DC") && val > 0 ? "+" : "";
  return `${prefix}${val.toFixed(2)}${unit}`;
}

function TrendBadge({ data, reKey, leKey }) {
  const reDelta = data[data.length-1][reKey] - data[0][reKey];
  const leDelta = data[data.length-1][leKey] - data[0][leKey];
  const stable = Math.abs(reDelta) < 0.1 && Math.abs(leDelta) < 0.1;
  return (
    <span style={{
      fontSize: 11, fontWeight: 600, letterSpacing: "0.06em",
      padding: "2px 8px", borderRadius: 20,
      background: stable ? "rgba(34,197,94,0.12)" : "rgba(251,146,60,0.12)",
      color: stable ? "#4ade80" : "#fb923c",
      textTransform: "uppercase"
    }}>
      {stable ? "Stable" : "Progressing"}
    </span>
  );
}

const CustomTooltip = ({ active, payload, label, metric }) => {
  if (!active || !payload?.length) return null;
  const re = payload.find(p => p.dataKey === metric.reKey);
  const le = payload.find(p => p.dataKey === metric.leKey);
  return (
    <div style={{
      background: "#0d1117", border: "1px solid #1e2d45",
      borderRadius: 10, padding: "10px 14px", fontSize: 13,
    }}>
      <div style={{ color: "#94a3b8", marginBottom: 6, fontWeight: 600 }}>{label}</div>
      {re && <div style={{ color: RE_COLOR }}>R&nbsp;&nbsp;{formatVal(re.value, metric.unit)}</div>}
      {le && <div style={{ color: LE_COLOR, marginTop: 2 }}>L&nbsp;&nbsp;{formatVal(le.value, metric.unit)}</div>}
    </div>
  );
};

export default function Chronicle() {
  const [activeMetric, setActiveMetric] = useState("sph");
  const [showRE, setShowRE] = useState(true);
  const [showLE, setShowLE] = useState(true);

  const metric = METRICS.find(m => m.key === activeMetric);
  const latest = DATA[DATA.length - 1];
  const prev = DATA[DATA.length - 2];

  const addData = DATA.filter(d => d.re_add !== null);

  return (
    <div style={{
      minHeight: "100vh",
      background: "#080c14",
      fontFamily: "'DM Sans', sans-serif",
      color: "#e2e8f0",
      maxWidth: 430,
      margin: "0 auto",
      paddingBottom: 40,
    }}>
      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@300;400;500;600&family=Cormorant+Garamond:ital,wght@0,400;0,600;1,400&display=swap');

        * { box-sizing: border-box; }

        .metric-tab {
          flex: 1; padding: 8px 4px; border: none;
          background: transparent; color: #4a5568;
          font-family: 'DM Sans', sans-serif;
          font-size: 12px; font-weight: 500;
          letter-spacing: 0.04em;
          cursor: pointer; border-radius: 8px;
          transition: all 0.18s ease;
          text-transform: uppercase;
        }
        .metric-tab.active {
          background: #0f1827;
          color: #e2e8f0;
        }
        .metric-tab:hover:not(.active) { color: #94a3b8; }

        .eye-toggle {
          display: flex; align-items: center; gap: 6px;
          padding: 6px 12px; border-radius: 20px;
          border: 1px solid transparent;
          font-family: 'DM Sans', sans-serif;
          font-size: 12px; font-weight: 500;
          cursor: pointer; transition: all 0.15s ease;
          background: transparent;
        }
        .eye-dot {
          width: 7px; height: 7px; border-radius: 50%;
        }

        .record-row {
          display: flex; align-items: flex-start;
          padding: 12px 0;
          border-bottom: 1px solid #0f1827;
          gap: 12px;
        }
        .record-row:last-child { border-bottom: none; }
      `}</style>

      {/* Header */}
      <div style={{ padding: "28px 20px 0" }}>
        <div style={{ display: "flex", alignItems: "baseline", gap: 10, marginBottom: 2 }}>
          <h1 style={{
            fontFamily: "'Cormorant Garamond', serif",
            fontSize: 28, fontWeight: 600, margin: 0,
            letterSpacing: "-0.01em", color: "#f1f5f9"
          }}>Chronicle</h1>
          <span style={{ fontSize: 12, color: "#3d4663", letterSpacing: "0.12em", textTransform: "uppercase", fontWeight: 500 }}>Optical</span>
        </div>
        <p style={{ fontSize: 12, color: "#3d4663", margin: 0, letterSpacing: "0.03em" }}>
          10 years · 10 records · Last tested 2024
        </p>
      </div>

      {/* Current Values Card */}
      <div style={{ padding: "16px 20px 0" }}>
        <div style={{
          background: "#0d1117",
          borderRadius: 14, padding: "16px",
          border: "1px solid #111827",
        }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", marginBottom: 14 }}>
            <span style={{ fontSize: 11, color: "#3d4663", letterSpacing: "0.1em", textTransform: "uppercase", fontWeight: 600 }}>Current prescription · 2024</span>
            <TrendBadge data={DATA} reKey="re_sph" leKey="le_sph" />
          </div>
          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 0 }}>
            {/* Right Eye */}
            <div style={{ borderRight: "1px solid #111827", paddingRight: 14 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 6, marginBottom: 8 }}>
                <div style={{ width: 6, height: 6, borderRadius: "50%", background: RE_COLOR }}></div>
                <span style={{ fontSize: 11, color: RE_COLOR, fontWeight: 600, letterSpacing: "0.08em" }}>RIGHT EYE</span>
              </div>
              {[["SPH", formatVal(latest.re_sph, "DS")], ["CYL", formatVal(latest.re_cyl, "DC")], ["Axis", `${latest.re_axis}°`], ["ADD", formatVal(latest.re_add, "DS")]].map(([label, val]) => (
                <div key={label} style={{ display: "flex", justifyContent: "space-between", marginBottom: 4 }}>
                  <span style={{ fontSize: 12, color: "#3d4663" }}>{label}</span>
                  <span style={{ fontSize: 12, color: "#94a3b8", fontWeight: 500 }}>{val}</span>
                </div>
              ))}
            </div>
            {/* Left Eye */}
            <div style={{ paddingLeft: 14 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 6, marginBottom: 8 }}>
                <div style={{ width: 6, height: 6, borderRadius: "50%", background: LE_COLOR }}></div>
                <span style={{ fontSize: 11, color: LE_COLOR, fontWeight: 600, letterSpacing: "0.08em" }}>LEFT EYE</span>
              </div>
              {[["SPH", formatVal(latest.le_sph, "DS")], ["CYL", formatVal(latest.le_cyl, "DC")], ["Axis", `${latest.le_axis}°`], ["ADD", formatVal(latest.le_add, "DS")]].map(([label, val]) => (
                <div key={label} style={{ display: "flex", justifyContent: "space-between", marginBottom: 4 }}>
                  <span style={{ fontSize: 12, color: "#3d4663" }}>{label}</span>
                  <span style={{ fontSize: 12, color: "#94a3b8", fontWeight: 500 }}>{val}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* Metric Tabs */}
      <div style={{ padding: "20px 20px 0" }}>
        <div style={{
          display: "flex", background: "#0a0e17",
          borderRadius: 10, padding: 4, gap: 2,
          border: "1px solid #0f1827",
        }}>
          {METRICS.map(m => (
            <button
              key={m.key}
              className={`metric-tab${activeMetric === m.key ? " active" : ""}`}
              onClick={() => setActiveMetric(m.key)}
            >
              {m.label}
            </button>
          ))}
        </div>
      </div>

      {/* Chart */}
      <div style={{ padding: "16px 20px 0" }}>
        <div style={{
          background: "#0d1117", borderRadius: 14,
          border: "1px solid #111827",
          padding: "16px 8px 12px",
        }}>
          {/* Chart header */}
          <div style={{ padding: "0 10px", marginBottom: 12 }}>
            <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
              <div>
                <div style={{ fontSize: 13, fontWeight: 600, color: "#94a3b8", marginBottom: 1 }}>{metric.label}</div>
                <div style={{ fontSize: 11, color: "#3d4663" }}>{metric.desc}</div>
              </div>
              {/* Eye toggles */}
              <div style={{ display: "flex", gap: 4 }}>
                <button
                  className="eye-toggle"
                  style={{
                    borderColor: showRE ? RE_COLOR : "#1e2535",
                    color: showRE ? RE_COLOR : "#3d4663",
                    opacity: showRE ? 1 : 0.5,
                  }}
                  onClick={() => setShowRE(r => !r)}
                >
                  <div className="eye-dot" style={{ background: RE_COLOR }}></div>
                  R
                </button>
                <button
                  className="eye-toggle"
                  style={{
                    borderColor: showLE ? LE_COLOR : "#1e2535",
                    color: showLE ? LE_COLOR : "#3d4663",
                    opacity: showLE ? 1 : 0.5,
                  }}
                  onClick={() => setShowLE(l => !l)}
                >
                  <div className="eye-dot" style={{ background: LE_COLOR }}></div>
                  L
                </button>
              </div>
            </div>
          </div>

          <ResponsiveContainer width="100%" height={180}>
            <LineChart
              data={metric.key === "add" ? addData : DATA}
              margin={{ top: 4, right: 12, bottom: 0, left: -8 }}
            >
              <CartesianGrid stroke={GRID_COLOR} strokeDasharray="0" vertical={false} />
              <XAxis
                dataKey="year"
                tick={{ fill: "#3d4663", fontSize: 10, fontFamily: "DM Sans" }}
                axisLine={{ stroke: AXIS_COLOR }}
                tickLine={false}
              />
              <YAxis
                domain={metric.domain}
                tick={{ fill: "#3d4663", fontSize: 10, fontFamily: "DM Sans" }}
                axisLine={false}
                tickLine={false}
                tickCount={metric.tickCount}
                tickFormatter={v => metric.key === "axis" ? `${v}°` : v.toFixed(2)}
              />
              <Tooltip content={<CustomTooltip metric={metric} />} cursor={{ stroke: "#1e2d45", strokeWidth: 1 }} />
              {showRE && (
                <Line
                  type="monotone" dataKey={metric.reKey}
                  stroke={RE_COLOR} strokeWidth={2}
                  dot={{ fill: RE_COLOR, r: 3, strokeWidth: 0 }}
                  activeDot={{ r: 5, fill: RE_COLOR, strokeWidth: 0 }}
                  connectNulls={false}
                />
              )}
              {showLE && (
                <Line
                  type="monotone" dataKey={metric.leKey}
                  stroke={LE_COLOR} strokeWidth={2}
                  dot={{ fill: LE_COLOR, r: 3, strokeWidth: 0 }}
                  activeDot={{ r: 5, fill: LE_COLOR, strokeWidth: 0 }}
                  connectNulls={false}
                />
              )}
            </LineChart>
          </ResponsiveContainer>

          {/* Insight */}
          <div style={{
            margin: "10px 10px 0",
            padding: "10px 12px",
            background: "#080c14",
            borderRadius: 8,
            fontSize: 12,
            color: "#4a5568",
            lineHeight: 1.5,
            borderLeft: "2px solid #1e2535",
          }}>
            {metric.note(DATA)}
          </div>
        </div>
      </div>

      {/* History */}
      <div style={{ padding: "20px 20px 0" }}>
        <div style={{ fontSize: 11, color: "#3d4663", letterSpacing: "0.1em", textTransform: "uppercase", fontWeight: 600, marginBottom: 12 }}>
          Record History
        </div>
        <div style={{ background: "#0d1117", borderRadius: 14, border: "1px solid #111827", padding: "0 16px" }}>
          {[...DATA].reverse().map((record, i) => {
            const reDelta = i < DATA.length - 1 ? record.re_sph - [...DATA].reverse()[i + 1]?.re_sph : 0;
            return (
              <div key={record.year} className="record-row">
                <div style={{ minWidth: 38 }}>
                  <span style={{ fontSize: 13, fontWeight: 600, color: "#475569" }}>{record.year}</span>
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ display: "flex", gap: 12, marginBottom: 3 }}>
                    <span style={{ fontSize: 12, color: "#64748b" }}>
                      <span style={{ color: "#3d4663" }}>R</span>&nbsp;
                      {formatVal(record.re_sph, "DS")} / {formatVal(record.re_cyl, "DC")} × {record.re_axis}°
                    </span>
                  </div>
                  <div style={{ display: "flex", gap: 12 }}>
                    <span style={{ fontSize: 12, color: "#64748b" }}>
                      <span style={{ color: "#3d4663" }}>L</span>&nbsp;
                      {formatVal(record.le_sph, "DS")} / {formatVal(record.le_cyl, "DC")} × {record.le_axis}°
                    </span>
                  </div>
                  {record.re_add && (
                    <div style={{ fontSize: 11, color: "#3d4663", marginTop: 3 }}>ADD {formatVal(record.re_add, "DS")}</div>
                  )}
                </div>
                {reDelta !== 0 && (
                  <div style={{
                    fontSize: 11, color: reDelta < 0 ? "#fb923c" : "#4ade80",
                    fontWeight: 600, minWidth: 36, textAlign: "right",
                    paddingTop: 2,
                  }}>
                    {reDelta > 0 ? "+" : ""}{reDelta.toFixed(2)}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* Reminder nudge */}
      <div style={{ padding: "16px 20px 0" }}>
        <div style={{
          background: "rgba(251,146,60,0.06)",
          border: "1px solid rgba(251,146,60,0.15)",
          borderRadius: 12, padding: "12px 14px",
          display: "flex", alignItems: "center", gap: 10,
        }}>
          <div style={{ fontSize: 18 }}>👁️</div>
          <div>
            <div style={{ fontSize: 12, fontWeight: 600, color: "#fb923c", marginBottom: 2 }}>Test due soon</div>
            <div style={{ fontSize: 12, color: "#4a5568" }}>Your last test was in 2024 · next expected April 2026</div>
          </div>
        </div>
      </div>
    </div>
  );
}
