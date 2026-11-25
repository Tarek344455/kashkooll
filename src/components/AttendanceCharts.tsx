import React from "react";
import { DailyAttendancePoint } from "../types/kashkool";

interface ChartProps {
  points: DailyAttendancePoint[];
  selectedIndex: number | null;
  onSelectIndex: (idx: number) => void;
}

export const AttendanceTrendAreaChart: React.FC<ChartProps> = ({
  points,
  selectedIndex,
  onSelectIndex,
}) => {
  if (points.length === 0) return null;
  const maxY = Math.max(4, ...points.map((p) => p.totalCount));
  const width = 640;
  const height = 210;
  const leftPad = 32;
  const rightPad = 16;
  const topPad = 14;
  const bottomPad = 16;
  const chartW = width - leftPad - rightPad;
  const chartH = height - topPad - bottomPad;
  const stepX = points.length <= 1 ? 0 : chartW / (points.length - 1);

  const ptCoord = (idx: number, val: number) => {
    const x = points.length === 1 ? leftPad + chartW / 2 : leftPad + idx * stepX;
    const ratio = Math.min(1, Math.max(0, val / maxY));
    const y = topPad + chartH * (1 - ratio);
    return { x, y };
  };

  const totalPts = points.map((p, idx) => ptCoord(idx, p.totalCount));
  const validPts = points.map((p, idx) => ptCoord(idx, p.validCount));

  const buildSmoothPath = (pts: Array<{ x: number; y: number }>) => {
    if (pts.length === 0) return "";
    let d = `M ${pts[0].x} ${pts[0].y}`;
    for (let i = 1; i < pts.length; i++) {
      const prev = pts[i - 1];
      const curr = pts[i];
      const midX = (prev.x + curr.x) / 2;
      d += ` C ${midX} ${prev.y}, ${midX} ${curr.y}, ${curr.x} ${curr.y}`;
    }
    return d;
  };

  const buildAreaPath = (pts: Array<{ x: number; y: number }>) => {
    if (pts.length === 0) return "";
    const baseLineY = topPad + chartH;
    const line = pts.map((p) => `L ${p.x} ${p.y}`).join(" ");
    return `M ${pts[0].x} ${baseLineY} ${line} L ${pts[pts.length - 1].x} ${baseLineY} Z`;
  };

  const stride = points.length <= 7 ? 1 : points.length <= 14 ? 3 : 6;

  return (
    <div className="w-full space-y-1.5" dir="ltr">
      <svg
        viewBox={`0 0 ${width} ${height}`}
        className="w-full h-52 overflow-visible select-none"
      >
        <defs>
          <linearGradient id="areaTotalGrad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#38BDF8" stopOpacity="0.35" />
            <stop offset="100%" stopColor="#38BDF8" stopOpacity="0.02" />
          </linearGradient>
          <linearGradient id="areaValidGrad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="#34D399" stopOpacity="0.24" />
            <stop offset="100%" stopColor="#34D399" stopOpacity="0.01" />
          </linearGradient>
        </defs>

        {[0, 0.25, 0.5, 0.75, 1].map((t, i) => {
          const y = topPad + chartH * t;
          return (
            <line
              key={i}
              x1={leftPad}
              x2={leftPad + chartW}
              y1={y}
              y2={y}
              stroke="rgba(255,255,255,0.12)"
              strokeDasharray="6 6"
              strokeWidth="1"
            />
          );
        })}

        <text x={8} y={topPad + 8} fill="#94A3B8" fontSize="11" className="font-mono-tabular">
          {maxY}
        </text>
        <text x={8} y={topPad + chartH + 2} fill="#94A3B8" fontSize="11" className="font-mono-tabular">
          0
        </text>

        <path d={buildAreaPath(totalPts)} fill="url(#areaTotalGrad)" />
        <path d={buildAreaPath(validPts)} fill="url(#areaValidGrad)" />

        <path
          d={buildSmoothPath(totalPts)}
          fill="none"
          stroke="#38BDF8"
          strokeWidth="3"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
        <path
          d={buildSmoothPath(validPts)}
          fill="none"
          stroke="#34D399"
          strokeWidth="2.5"
          strokeLinecap="round"
          strokeLinejoin="round"
        />

        {selectedIndex !== null && totalPts[selectedIndex] && (
          <line
            x1={totalPts[selectedIndex].x}
            x2={totalPts[selectedIndex].x}
            y1={topPad}
            y2={topPad + chartH}
            stroke="rgba(56, 189, 248, 0.45)"
            strokeWidth="1.5"
          />
        )}

        {points.map((p, idx) => {
          const ptT = totalPts[idx];
          const ptV = validPts[idx];
          const isSel = idx === selectedIndex;
          return (
            <g
              key={p.dayStartMillis}
              className="cursor-pointer"
              onClick={() => onSelectIndex(idx)}
            >
              <rect
                x={ptT.x - Math.max(10, stepX / 2)}
                y={topPad}
                width={Math.max(20, stepX || 24)}
                height={chartH}
                fill="transparent"
              />
              <circle cx={ptT.x} cy={ptT.y} r={isSel ? 6 : 3.5} fill="#38BDF8" />
              <circle cx={ptV.x} cy={ptV.y} r={isSel ? 5 : 2.8} fill="#34D399" />
              {p.dueCount > 0 && (
                <circle
                  cx={ptCoord(idx, p.dueCount).x}
                  cy={ptCoord(idx, p.dueCount).y}
                  r={3}
                  fill="#FBBF24"
                />
              )}
              {p.blockedCount > 0 && (
                <circle
                  cx={ptCoord(idx, p.blockedCount).x}
                  cy={ptCoord(idx, p.blockedCount).y}
                  r={3}
                  fill="#F87171"
                />
              )}
            </g>
          );
        })}
      </svg>

      <div className="flex items-center justify-between ps-7 pe-2 text-[11px] text-[#94A3B8] font-mono-tabular">
        {points.map((pt, idx) =>
          idx === 0 || idx === points.length - 1 || idx % stride === 0 ? (
            <span key={pt.dayStartMillis}>{pt.shortLabel}</span>
          ) : null
        )}
      </div>
    </div>
  );
};

export const AttendanceStackedBarChart: React.FC<ChartProps> = ({
  points,
  selectedIndex,
  onSelectIndex,
}) => {
  if (points.length === 0) return null;
  const maxY = Math.max(4, ...points.map((p) => p.totalCount));
  const width = 640;
  const height = 210;
  const leftPad = 28;
  const rightPad = 10;
  const topPad = 14;
  const bottomPad = 16;
  const chartW = width - leftPad - rightPad;
  const chartH = height - topPad - bottomPad;
  const slotW = chartW / points.length;
  const barW = Math.min(24, Math.max(6, slotW * 0.56));
  const stride = points.length <= 7 ? 1 : points.length <= 14 ? 3 : 6;

  return (
    <div className="w-full space-y-1.5" dir="ltr">
      <svg
        viewBox={`0 0 ${width} ${height}`}
        className="w-full h-52 overflow-visible select-none"
      >
        {[0, 0.25, 0.5, 0.75, 1].map((t, i) => {
          const y = topPad + chartH * t;
          return (
            <line
              key={i}
              x1={leftPad}
              x2={leftPad + chartW}
              y1={y}
              y2={y}
              stroke="rgba(255,255,255,0.12)"
              strokeDasharray="6 6"
              strokeWidth="1"
            />
          );
        })}

        <text x={4} y={topPad + 8} fill="#94A3B8" fontSize="11" className="font-mono-tabular">
          {maxY}
        </text>
        <text x={4} y={topPad + chartH + 2} fill="#94A3B8" fontSize="11" className="font-mono-tabular">
          0
        </text>

        {points.map((p, idx) => {
          const x = leftPad + idx * slotW + (slotW - barW) / 2;
          const isSel = idx === selectedIndex;
          const segments: Array<{ count: number; color: string }> = [
            { count: p.validCount, color: "#34D399" },
            { count: p.dueCount, color: "#FBBF24" },
            { count: p.blockedCount, color: "#F87171" },
          ];
          let currentBottom = topPad + chartH;

          return (
            <g
              key={p.dayStartMillis}
              className="cursor-pointer"
              onClick={() => onSelectIndex(idx)}
            >
              <rect
                x={leftPad + idx * slotW}
                y={topPad}
                width={slotW}
                height={chartH}
                rx={6}
                fill={isSel ? "rgba(56, 189, 248, 0.14)" : "transparent"}
              />
              {segments.map((seg, sIdx) => {
                if (seg.count <= 0) return null;
                const segH = (seg.count / maxY) * chartH;
                const segTop = Math.max(topPad, currentBottom - segH);
                const rectH = Math.max(2, currentBottom - segTop);
                currentBottom = segTop;
                return (
                  <rect
                    key={sIdx}
                    x={x}
                    y={segTop}
                    width={barW}
                    height={rectH}
                    rx={3}
                    fill={seg.color}
                  />
                );
              })}
            </g>
          );
        })}
      </svg>

      <div className="flex items-center justify-between ps-7 pe-2 text-[11px] text-[#94A3B8] font-mono-tabular">
        {points.map((pt, idx) =>
          idx === 0 || idx === points.length - 1 || idx % stride === 0 ? (
            <span key={pt.dayStartMillis}>{pt.shortLabel}</span>
          ) : null
        )}
      </div>
    </div>
  );
};
