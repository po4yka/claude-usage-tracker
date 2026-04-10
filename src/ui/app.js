// src/ui/app.tsx
import { render } from "preact";

// src/ui/components/Footer.tsx
import { jsx, jsxs } from "preact/jsx-runtime";
function Footer() {
  return /* @__PURE__ */ jsx("footer", { children: /* @__PURE__ */ jsxs("div", { class: "footer-content", children: [
    /* @__PURE__ */ jsxs("p", { children: [
      "Cost estimates based on Anthropic API pricing (",
      /* @__PURE__ */ jsx(
        "a",
        {
          href: "https://docs.anthropic.com/en/docs/about-claude/pricing",
          target: "_blank",
          rel: "noopener noreferrer",
          children: "docs.anthropic.com/pricing"
        }
      ),
      "). Actual costs for Max/Pro subscribers differ."
    ] }),
    /* @__PURE__ */ jsxs("p", { children: [
      "GitHub:",
      " ",
      /* @__PURE__ */ jsx(
        "a",
        {
          href: "https://github.com/po4yka/claude-usage-tracker",
          target: "_blank",
          rel: "noopener noreferrer",
          children: "po4yka/claude-usage-tracker"
        }
      ),
      " ",
      "\xB7 License: MIT"
    ] })
  ] }) });
}

// src/ui/lib/charts.ts
var TOKEN_COLORS = {
  input: "rgba(59,130,246,0.8)",
  // blue
  output: "rgba(167,139,250,0.8)",
  // purple
  cache_read: "rgba(34,197,94,0.5)",
  // green
  cache_creation: "rgba(234,179,8,0.5)"
  // yellow
};
var MODEL_COLORS = ["#6366f1", "#3b82f6", "#22c55e", "#a78bfa", "#eab308", "#f472b6", "#14b8a6", "#60a5fa"];
var RANGE_LABELS = {
  "7d": "Last 7 Days",
  "30d": "Last 30 Days",
  "90d": "Last 90 Days",
  "all": "All Time"
};
var RANGE_TICKS = { "7d": 7, "30d": 15, "90d": 13, "all": 12 };
function apexThemeMode() {
  return document.documentElement.getAttribute("data-theme") === "light" ? "light" : "dark";
}
function cssVar(name) {
  return getComputedStyle(document.documentElement).getPropertyValue(name).trim();
}

// src/ui/lib/format.ts
function esc(s2) {
  const d3 = document.createElement("div");
  d3.textContent = String(s2);
  return d3.innerHTML;
}
function $(id) {
  return document.getElementById(id);
}
function fmt(n3) {
  if (n3 >= 1e9) return (n3 / 1e9).toFixed(2) + "B";
  if (n3 >= 1e6) return (n3 / 1e6).toFixed(2) + "M";
  if (n3 >= 1e3) return (n3 / 1e3).toFixed(1) + "K";
  return n3.toLocaleString();
}
function fmtCost(c2) {
  return "$" + c2.toFixed(4);
}
function fmtCostBig(c2) {
  return "$" + c2.toFixed(2);
}
function fmtResetTime(minutes) {
  if (minutes == null || minutes <= 0) return "now";
  if (minutes >= 1440) return Math.floor(minutes / 1440) + "d " + Math.floor(minutes % 1440 / 60) + "h";
  if (minutes >= 60) return Math.floor(minutes / 60) + "h " + minutes % 60 + "m";
  return minutes + "m";
}
function progressColor(percent) {
  if (percent >= 90) return cssVar("--red");
  if (percent >= 70) return cssVar("--yellow");
  return cssVar("--green");
}

// node_modules/@preact/signals/dist/signals.module.js
import { Component as i2, options as n2, isValidElement as r2, Fragment as t2 } from "preact";
import { useMemo as o2, useRef as e2, useEffect as f2 } from "preact/hooks";

// node_modules/@preact/signals-core/dist/signals-core.module.js
var i = /* @__PURE__ */ Symbol.for("preact-signals");
function t() {
  if (!(s > 1)) {
    var i3, t3 = false;
    !(function() {
      var i4 = c;
      c = void 0;
      while (void 0 !== i4) {
        if (i4.S.v === i4.v) i4.S.i = i4.i;
        i4 = i4.o;
      }
    })();
    while (void 0 !== h) {
      var n3 = h;
      h = void 0;
      v++;
      while (void 0 !== n3) {
        var r3 = n3.u;
        n3.u = void 0;
        n3.f &= -3;
        if (!(8 & n3.f) && w(n3)) try {
          n3.c();
        } catch (n4) {
          if (!t3) {
            i3 = n4;
            t3 = true;
          }
        }
        n3 = r3;
      }
    }
    v = 0;
    s--;
    if (t3) throw i3;
  } else s--;
}
function n(i3) {
  if (s > 0) return i3();
  e = ++u;
  s++;
  try {
    return i3();
  } finally {
    t();
  }
}
var r = void 0;
function o(i3) {
  var t3 = r;
  r = void 0;
  try {
    return i3();
  } finally {
    r = t3;
  }
}
var f;
var h = void 0;
var s = 0;
var v = 0;
var u = 0;
var e = 0;
var c = void 0;
var d = 0;
function a(i3) {
  if (void 0 !== r) {
    var t3 = i3.n;
    if (void 0 === t3 || t3.t !== r) {
      t3 = { i: 0, S: i3, p: r.s, n: void 0, t: r, e: void 0, x: void 0, r: t3 };
      if (void 0 !== r.s) r.s.n = t3;
      r.s = t3;
      i3.n = t3;
      if (32 & r.f) i3.S(t3);
      return t3;
    } else if (-1 === t3.i) {
      t3.i = 0;
      if (void 0 !== t3.n) {
        t3.n.p = t3.p;
        if (void 0 !== t3.p) t3.p.n = t3.n;
        t3.p = r.s;
        t3.n = void 0;
        r.s.n = t3;
        r.s = t3;
      }
      return t3;
    }
  }
}
function l(i3, t3) {
  this.v = i3;
  this.i = 0;
  this.n = void 0;
  this.t = void 0;
  this.l = 0;
  this.W = null == t3 ? void 0 : t3.watched;
  this.Z = null == t3 ? void 0 : t3.unwatched;
  this.name = null == t3 ? void 0 : t3.name;
}
l.prototype.brand = i;
l.prototype.h = function() {
  return true;
};
l.prototype.S = function(i3) {
  var t3 = this, n3 = this.t;
  if (n3 !== i3 && void 0 === i3.e) {
    i3.x = n3;
    this.t = i3;
    if (void 0 !== n3) n3.e = i3;
    else o(function() {
      var i4;
      null == (i4 = t3.W) || i4.call(t3);
    });
  }
};
l.prototype.U = function(i3) {
  var t3 = this;
  if (void 0 !== this.t) {
    var n3 = i3.e, r3 = i3.x;
    if (void 0 !== n3) {
      n3.x = r3;
      i3.e = void 0;
    }
    if (void 0 !== r3) {
      r3.e = n3;
      i3.x = void 0;
    }
    if (i3 === this.t) {
      this.t = r3;
      if (void 0 === r3) o(function() {
        var i4;
        null == (i4 = t3.Z) || i4.call(t3);
      });
    }
  }
};
l.prototype.subscribe = function(i3) {
  var t3 = this;
  return j(function() {
    var n3 = t3.value, o3 = r;
    r = void 0;
    try {
      i3(n3);
    } finally {
      r = o3;
    }
  }, { name: "sub" });
};
l.prototype.valueOf = function() {
  return this.value;
};
l.prototype.toString = function() {
  return this.value + "";
};
l.prototype.toJSON = function() {
  return this.value;
};
l.prototype.peek = function() {
  var i3 = r;
  r = void 0;
  try {
    return this.value;
  } finally {
    r = i3;
  }
};
Object.defineProperty(l.prototype, "value", { get: function() {
  var i3 = a(this);
  if (void 0 !== i3) i3.i = this.i;
  return this.v;
}, set: function(i3) {
  if (i3 !== this.v) {
    if (v > 100) throw new Error("Cycle detected");
    !(function(i4) {
      if (0 !== s && 0 === v) {
        if (i4.l !== e) {
          i4.l = e;
          c = { S: i4, v: i4.v, i: i4.i, o: c };
        }
      }
    })(this);
    this.v = i3;
    this.i++;
    d++;
    s++;
    try {
      for (var n3 = this.t; void 0 !== n3; n3 = n3.x) n3.t.N();
    } finally {
      t();
    }
  }
} });
function y(i3, t3) {
  return new l(i3, t3);
}
function w(i3) {
  for (var t3 = i3.s; void 0 !== t3; t3 = t3.n) if (t3.S.i !== t3.i || !t3.S.h() || t3.S.i !== t3.i) return true;
  return false;
}
function _(i3) {
  for (var t3 = i3.s; void 0 !== t3; t3 = t3.n) {
    var n3 = t3.S.n;
    if (void 0 !== n3) t3.r = n3;
    t3.S.n = t3;
    t3.i = -1;
    if (void 0 === t3.n) {
      i3.s = t3;
      break;
    }
  }
}
function b(i3) {
  var t3 = i3.s, n3 = void 0;
  while (void 0 !== t3) {
    var r3 = t3.p;
    if (-1 === t3.i) {
      t3.S.U(t3);
      if (void 0 !== r3) r3.n = t3.n;
      if (void 0 !== t3.n) t3.n.p = r3;
    } else n3 = t3;
    t3.S.n = t3.r;
    if (void 0 !== t3.r) t3.r = void 0;
    t3 = r3;
  }
  i3.s = n3;
}
function p(i3, t3) {
  l.call(this, void 0);
  this.x = i3;
  this.s = void 0;
  this.g = d - 1;
  this.f = 4;
  this.W = null == t3 ? void 0 : t3.watched;
  this.Z = null == t3 ? void 0 : t3.unwatched;
  this.name = null == t3 ? void 0 : t3.name;
}
p.prototype = new l();
p.prototype.h = function() {
  this.f &= -3;
  if (1 & this.f) return false;
  if (32 == (36 & this.f)) return true;
  this.f &= -5;
  if (this.g === d) return true;
  this.g = d;
  this.f |= 1;
  if (this.i > 0 && !w(this)) {
    this.f &= -2;
    return true;
  }
  var i3 = r;
  try {
    _(this);
    r = this;
    var t3 = this.x();
    if (16 & this.f || this.v !== t3 || 0 === this.i) {
      this.v = t3;
      this.f &= -17;
      this.i++;
    }
  } catch (i4) {
    this.v = i4;
    this.f |= 16;
    this.i++;
  }
  r = i3;
  b(this);
  this.f &= -2;
  return true;
};
p.prototype.S = function(i3) {
  if (void 0 === this.t) {
    this.f |= 36;
    for (var t3 = this.s; void 0 !== t3; t3 = t3.n) t3.S.S(t3);
  }
  l.prototype.S.call(this, i3);
};
p.prototype.U = function(i3) {
  if (void 0 !== this.t) {
    l.prototype.U.call(this, i3);
    if (void 0 === this.t) {
      this.f &= -33;
      for (var t3 = this.s; void 0 !== t3; t3 = t3.n) t3.S.U(t3);
    }
  }
};
p.prototype.N = function() {
  if (!(2 & this.f)) {
    this.f |= 6;
    for (var i3 = this.t; void 0 !== i3; i3 = i3.x) i3.t.N();
  }
};
Object.defineProperty(p.prototype, "value", { get: function() {
  if (1 & this.f) throw new Error("Cycle detected");
  var i3 = a(this);
  this.h();
  if (void 0 !== i3) i3.i = this.i;
  if (16 & this.f) throw this.v;
  return this.v;
} });
function g(i3, t3) {
  return new p(i3, t3);
}
function S(i3) {
  var n3 = i3.m;
  i3.m = void 0;
  if ("function" == typeof n3) {
    s++;
    var o3 = r;
    r = void 0;
    try {
      n3();
    } catch (t3) {
      i3.f &= -2;
      i3.f |= 8;
      m(i3);
      throw t3;
    } finally {
      r = o3;
      t();
    }
  }
}
function m(i3) {
  for (var t3 = i3.s; void 0 !== t3; t3 = t3.n) t3.S.U(t3);
  i3.x = void 0;
  i3.s = void 0;
  S(i3);
}
function x(i3) {
  if (r !== this) throw new Error("Out-of-order effect");
  b(this);
  r = i3;
  this.f &= -2;
  if (8 & this.f) m(this);
  t();
}
function E(i3, t3) {
  this.x = i3;
  this.m = void 0;
  this.s = void 0;
  this.u = void 0;
  this.f = 32;
  this.name = null == t3 ? void 0 : t3.name;
  if (f) f.push(this);
}
E.prototype.c = function() {
  var i3 = this.S();
  try {
    if (8 & this.f) return;
    if (void 0 === this.x) return;
    var t3 = this.x();
    if ("function" == typeof t3) this.m = t3;
  } finally {
    i3();
  }
};
E.prototype.S = function() {
  if (1 & this.f) throw new Error("Cycle detected");
  this.f |= 1;
  this.f &= -9;
  S(this);
  _(this);
  s++;
  var i3 = r;
  r = this;
  return x.bind(this, i3);
};
E.prototype.N = function() {
  if (!(2 & this.f)) {
    this.f |= 2;
    this.u = h;
    h = this;
  }
};
E.prototype.d = function() {
  this.f |= 8;
  if (!(1 & this.f)) m(this);
};
E.prototype.dispose = function() {
  this.d();
};
function j(i3, t3) {
  var n3 = new E(i3, t3);
  try {
    n3.c();
  } catch (i4) {
    n3.d();
    throw i4;
  }
  var r3 = n3.d.bind(n3);
  r3[Symbol.dispose] = r3;
  return r3;
}

// node_modules/@preact/signals/dist/signals.module.js
var l2;
var d2;
var h2;
var p2 = "undefined" != typeof window && !!window.__PREACT_SIGNALS_DEVTOOLS__;
var _2 = [];
j(function() {
  l2 = this.N;
})();
function g2(i3, r3) {
  n2[i3] = r3.bind(null, n2[i3] || function() {
  });
}
function b2(i3) {
  if (h2) {
    var n3 = h2;
    h2 = void 0;
    n3();
  }
  h2 = i3 && i3.S();
}
function y2(i3) {
  var n3 = this, t3 = i3.data, e3 = useSignal(t3);
  e3.value = t3;
  var f3 = o2(function() {
    var i4 = n3, t4 = n3.__v;
    while (t4 = t4.__) if (t4.__c) {
      t4.__c.__$f |= 4;
      break;
    }
    var o3 = g(function() {
      var i5 = e3.value.value;
      return 0 === i5 ? 0 : true === i5 ? "" : i5 || "";
    }), f4 = g(function() {
      return !Array.isArray(o3.value) && !r2(o3.value);
    }), a3 = j(function() {
      this.N = F;
      if (f4.value) {
        var n4 = o3.value;
        if (i4.__v && i4.__v.__e && 3 === i4.__v.__e.nodeType) i4.__v.__e.data = n4;
      }
    }), v3 = n3.__$u.d;
    n3.__$u.d = function() {
      a3();
      v3.call(this);
    };
    return [f4, o3];
  }, []), a2 = f3[0], v2 = f3[1];
  return a2.value ? v2.peek() : v2.value;
}
y2.displayName = "ReactiveTextNode";
Object.defineProperties(l.prototype, { constructor: { configurable: true, value: void 0 }, type: { configurable: true, value: y2 }, props: { configurable: true, get: function() {
  var i3 = this;
  return { data: { get value() {
    return i3.value;
  } } };
} }, __b: { configurable: true, value: 1 } });
g2("__b", function(i3, n3) {
  if ("string" == typeof n3.type) {
    var r3, t3 = n3.props;
    for (var o3 in t3) if ("children" !== o3) {
      var e3 = t3[o3];
      if (e3 instanceof l) {
        if (!r3) n3.__np = r3 = {};
        r3[o3] = e3;
        t3[o3] = e3.peek();
      }
    }
  }
  i3(n3);
});
g2("__r", function(i3, n3) {
  i3(n3);
  if (n3.type !== t2) {
    b2();
    var r3, o3 = n3.__c;
    if (o3) {
      o3.__$f &= -2;
      if (void 0 === (r3 = o3.__$u)) o3.__$u = r3 = (function(i4, n4) {
        var r4;
        j(function() {
          r4 = this;
        }, { name: n4 });
        r4.c = i4;
        return r4;
      })(function() {
        var i4;
        if (p2) null == (i4 = r3.y) || i4.call(r3);
        o3.__$f |= 1;
        o3.setState({});
      }, "function" == typeof n3.type ? n3.type.displayName || n3.type.name : "");
    }
    d2 = o3;
    b2(r3);
  }
});
g2("__e", function(i3, n3, r3, t3) {
  b2();
  d2 = void 0;
  i3(n3, r3, t3);
});
g2("diffed", function(i3, n3) {
  b2();
  d2 = void 0;
  var r3;
  if ("string" == typeof n3.type && (r3 = n3.__e)) {
    var t3 = n3.__np, o3 = n3.props;
    if (t3) {
      var e3 = r3.U;
      if (e3) for (var f3 in e3) {
        var u2 = e3[f3];
        if (void 0 !== u2 && !(f3 in t3)) {
          u2.d();
          e3[f3] = void 0;
        }
      }
      else {
        e3 = {};
        r3.U = e3;
      }
      for (var a2 in t3) {
        var c2 = e3[a2], v2 = t3[a2];
        if (void 0 === c2) {
          c2 = w2(r3, a2, v2);
          e3[a2] = c2;
        } else c2.o(v2, o3);
      }
      for (var s2 in t3) o3[s2] = t3[s2];
    }
  }
  i3(n3);
});
function w2(i3, n3, r3, t3) {
  var o3 = n3 in i3 && void 0 === i3.ownerSVGElement, e3 = y(r3), f3 = r3.peek();
  return { o: function(i4, n4) {
    e3.value = i4;
    f3 = i4.peek();
  }, d: j(function() {
    this.N = F;
    var r4 = e3.value.value;
    if (f3 !== r4) {
      f3 = void 0;
      if (o3) i3[n3] = r4;
      else if (null != r4 && (false !== r4 || "-" === n3[4])) i3.setAttribute(n3, r4);
      else i3.removeAttribute(n3);
    } else f3 = void 0;
  }) };
}
g2("unmount", function(i3, n3) {
  if ("string" == typeof n3.type) {
    var r3 = n3.__e;
    if (r3) {
      var t3 = r3.U;
      if (t3) {
        r3.U = void 0;
        for (var o3 in t3) {
          var e3 = t3[o3];
          if (e3) e3.d();
        }
      }
    }
    n3.__np = void 0;
  } else {
    var f3 = n3.__c;
    if (f3) {
      var u2 = f3.__$u;
      if (u2) {
        f3.__$u = void 0;
        u2.d();
      }
    }
  }
  i3(n3);
});
g2("__h", function(i3, n3, r3, t3) {
  if (t3 < 3 || 9 === t3) n3.__$f |= 2;
  i3(n3, r3, t3);
});
i2.prototype.shouldComponentUpdate = function(i3, n3) {
  if (this.__R) return true;
  var r3 = this.__$u, t3 = r3 && void 0 !== r3.s;
  for (var o3 in n3) return true;
  if (this.__f || "boolean" == typeof this.u && true === this.u) {
    var e3 = 2 & this.__$f;
    if (!(t3 || e3 || 4 & this.__$f)) return true;
    if (1 & this.__$f) return true;
  } else {
    if (!(t3 || 4 & this.__$f)) return true;
    if (3 & this.__$f) return true;
  }
  for (var f3 in i3) if ("__source" !== f3 && i3[f3] !== this.props[f3]) return true;
  for (var u2 in this.props) if (!(u2 in i3)) return true;
  return false;
};
function useSignal(i3, n3) {
  return o2(function() {
    return y(i3, n3);
  }, []);
}
var q = function(i3) {
  queueMicrotask(function() {
    queueMicrotask(i3);
  });
};
function x2() {
  n(function() {
    var i3;
    while (i3 = _2.shift()) l2.call(i3);
  });
}
function F() {
  if (1 === _2.push(this)) (n2.requestAnimationFrame || q)(x2);
}

// src/ui/state/store.ts
var rawData = y(null);
var selectedModels = y(/* @__PURE__ */ new Set());
var selectedRange = y("30d");
var projectSearchQuery = y("");
var SESSIONS_PAGE_SIZE = 25;
var lastFilteredSessions = y([]);
var lastByProject = y([]);

// src/ui/components/StatsCards.tsx
import { Fragment, jsx as jsx2, jsxs as jsxs2 } from "preact/jsx-runtime";
function StatsCards({ totals }) {
  const rangeLabel = RANGE_LABELS[selectedRange.value].toLowerCase();
  const stats = [
    { label: "Sessions", value: totals.sessions.toLocaleString(), sub: rangeLabel },
    { label: "Turns", value: fmt(totals.turns), sub: rangeLabel },
    { label: "Input Tokens", value: fmt(totals.input), sub: rangeLabel },
    { label: "Output Tokens", value: fmt(totals.output), sub: rangeLabel },
    { label: "Cache Read", value: fmt(totals.cache_read), sub: "prompt cache" },
    { label: "Cache Creation", value: fmt(totals.cache_creation), sub: "cache writes" },
    { label: "Est. Cost", value: fmtCostBig(totals.cost), sub: "API pricing", isCost: true }
  ];
  return /* @__PURE__ */ jsx2(Fragment, { children: stats.map((s2) => /* @__PURE__ */ jsx2("div", { class: "card stat-card", children: /* @__PURE__ */ jsxs2("div", { class: "stat-content", children: [
    /* @__PURE__ */ jsx2("div", { class: "stat-label", children: s2.label }),
    /* @__PURE__ */ jsx2("div", { class: `stat-value ${s2.isCost ? "cost-value" : ""}`, children: s2.value }),
    s2.sub ? /* @__PURE__ */ jsx2("div", { class: "stat-sub", children: s2.sub }) : null
  ] }) }, s2.label)) });
}

// src/ui/components/Toast.tsx
import { jsx as jsx3 } from "preact/jsx-runtime";
var toasts = y([]);
var toastId = 0;
function showError(msg) {
  const id = ++toastId;
  toasts.value = [...toasts.value, { text: msg, type: "error", id }];
  setTimeout(() => {
    toasts.value = toasts.value.filter((t3) => t3.id !== id);
  }, 6e3);
}
function showSuccess(msg) {
  const id = ++toastId;
  toasts.value = [...toasts.value, { text: msg, type: "success", id }];
  setTimeout(() => {
    toasts.value = toasts.value.filter((t3) => t3.id !== id);
  }, 6e3);
}
function ToastContainer() {
  return /* @__PURE__ */ jsx3("div", { style: {
    position: "fixed",
    top: 56,
    right: 16,
    zIndex: 999,
    display: "flex",
    flexDirection: "column",
    gap: "8px"
  }, children: toasts.value.map((t3) => /* @__PURE__ */ jsx3("div", { style: {
    background: `var(--toast-${t3.type === "error" ? "error" : "success"}-bg)`,
    color: `var(--toast-${t3.type === "error" ? "error" : "success"}-text)`,
    padding: "10px 16px",
    borderRadius: "8px",
    fontSize: "12px",
    fontWeight: 500,
    maxWidth: "360px",
    border: "1px solid var(--border)",
    animation: "slideIn 0.2s ease-out"
  }, children: t3.text }, t3.id)) });
}

// src/ui/components/SubagentSummary.tsx
import { jsx as jsx4, jsxs as jsxs3 } from "preact/jsx-runtime";
function SubagentSummary({ summary }) {
  if (summary.subagent_turns === 0) return null;
  const totalInput = summary.parent_input + summary.subagent_input;
  const totalOutput = summary.parent_output + summary.subagent_output;
  const subPctInput = totalInput > 0 ? summary.subagent_input / totalInput * 100 : 0;
  const subPctOutput = totalOutput > 0 ? summary.subagent_output / totalOutput * 100 : 0;
  return /* @__PURE__ */ jsxs3("div", { class: "table-card", children: [
    /* @__PURE__ */ jsx4("div", { class: "section-title", children: "Subagent Breakdown" }),
    /* @__PURE__ */ jsxs3("div", { style: "display:grid;grid-template-columns:1fr 1fr 1fr;gap:16px", children: [
      /* @__PURE__ */ jsxs3("div", { children: [
        /* @__PURE__ */ jsx4("div", { class: "label", style: "color:var(--muted);font-size:11px;text-transform:uppercase;margin-bottom:4px", children: "Turns" }),
        /* @__PURE__ */ jsxs3("div", { style: "font-size:15px", children: [
          "Parent: ",
          /* @__PURE__ */ jsx4("strong", { children: fmt(summary.parent_turns) })
        ] }),
        /* @__PURE__ */ jsxs3("div", { style: "font-size:15px", children: [
          "Subagent: ",
          /* @__PURE__ */ jsx4("strong", { children: fmt(summary.subagent_turns) })
        ] }),
        /* @__PURE__ */ jsxs3("div", { class: "sub", children: [
          summary.unique_agents,
          " unique agents"
        ] })
      ] }),
      /* @__PURE__ */ jsxs3("div", { children: [
        /* @__PURE__ */ jsx4("div", { class: "label", style: "color:var(--muted);font-size:11px;text-transform:uppercase;margin-bottom:4px", children: "Input Tokens" }),
        /* @__PURE__ */ jsxs3("div", { style: "font-size:15px", children: [
          "Parent: ",
          /* @__PURE__ */ jsx4("strong", { children: fmt(summary.parent_input) })
        ] }),
        /* @__PURE__ */ jsxs3("div", { style: "font-size:15px", children: [
          "Subagent: ",
          /* @__PURE__ */ jsx4("strong", { children: fmt(summary.subagent_input) }),
          " (",
          subPctInput.toFixed(1),
          "%)"
        ] })
      ] }),
      /* @__PURE__ */ jsxs3("div", { children: [
        /* @__PURE__ */ jsx4("div", { class: "label", style: "color:var(--muted);font-size:11px;text-transform:uppercase;margin-bottom:4px", children: "Output Tokens" }),
        /* @__PURE__ */ jsxs3("div", { style: "font-size:15px", children: [
          "Parent: ",
          /* @__PURE__ */ jsx4("strong", { children: fmt(summary.parent_output) })
        ] }),
        /* @__PURE__ */ jsxs3("div", { style: "font-size:15px", children: [
          "Subagent: ",
          /* @__PURE__ */ jsx4("strong", { children: fmt(summary.subagent_output) }),
          " (",
          subPctOutput.toFixed(1),
          "%)"
        ] })
      ] })
    ] })
  ] });
}

// src/ui/components/DataTable.tsx
import { useState, useRef, useEffect } from "preact/hooks";
import {
  createTable,
  getCoreRowModel,
  getSortedRowModel,
  getPaginationRowModel
} from "@tanstack/table-core";
import { jsx as jsx5, jsxs as jsxs4 } from "preact/jsx-runtime";
function renderCell(cell) {
  const def = cell.column.columnDef.cell;
  if (typeof def === "function") {
    return def(cell.getContext());
  }
  return cell.getValue();
}
function renderHeader(header) {
  const def = header.column.columnDef.header;
  if (typeof def === "function") {
    return def(header.getContext());
  }
  return def;
}
function resolveUpdater(updater, prev) {
  return typeof updater === "function" ? updater(prev) : updater;
}
function DataTable({
  columns: columns7,
  data,
  title,
  exportFn,
  pageSize,
  defaultSort: defaultSort4,
  enableColumnVisibility
}) {
  const [sorting, setSorting] = useState(defaultSort4 || []);
  const [pagination, setPagination] = useState({
    pageIndex: 0,
    pageSize: pageSize || data.length || 100
  });
  const [columnVisibility, setColumnVisibility] = useState({});
  const [, rerender] = useState(0);
  useEffect(() => {
    setPagination((prev) => ({ ...prev, pageIndex: 0 }));
  }, [data]);
  const tableRef = useRef(null);
  const stateRef = useRef({ sorting, pagination, columnVisibility });
  stateRef.current = { sorting, pagination, columnVisibility };
  if (!tableRef.current) {
    tableRef.current = createTable({
      columns: columns7,
      data,
      state: { sorting, pagination, columnVisibility, columnPinning: { left: [], right: [] } },
      onStateChange: (updater) => {
        const newState = resolveUpdater(updater, tableRef.current.getState());
        if (newState.sorting !== stateRef.current.sorting) setSorting(newState.sorting);
        if (newState.pagination !== stateRef.current.pagination) setPagination(newState.pagination);
        if (newState.columnVisibility !== stateRef.current.columnVisibility) setColumnVisibility(newState.columnVisibility);
        rerender((n3) => n3 + 1);
      },
      onSortingChange: (updater) => setSorting((prev) => resolveUpdater(updater, prev)),
      onPaginationChange: (updater) => setPagination((prev) => resolveUpdater(updater, prev)),
      onColumnVisibilityChange: (updater) => setColumnVisibility((prev) => resolveUpdater(updater, prev)),
      getCoreRowModel: getCoreRowModel(),
      getSortedRowModel: getSortedRowModel(),
      ...pageSize ? { getPaginationRowModel: getPaginationRowModel() } : {},
      renderFallbackValue: ""
    });
  }
  tableRef.current.setOptions((prev) => ({
    ...prev,
    columns: columns7,
    data,
    state: { ...tableRef.current.getState(), sorting, pagination, columnVisibility }
  }));
  const table = tableRef.current;
  const headerGroups = table.getHeaderGroups();
  const rows = table.getRowModel().rows;
  return /* @__PURE__ */ jsxs4("div", { class: "table-card", children: [
    (title || exportFn) && /* @__PURE__ */ jsxs4("div", { class: exportFn ? "section-header" : "", children: [
      title && /* @__PURE__ */ jsx5("div", { class: "section-title", children: title }),
      exportFn && /* @__PURE__ */ jsx5("button", { class: "export-btn", onClick: exportFn, title: "Export to CSV", children: "\u2913 CSV" })
    ] }),
    enableColumnVisibility && /* @__PURE__ */ jsx5("div", { class: "column-toggle", children: table.getAllLeafColumns().map((column) => /* @__PURE__ */ jsxs4("label", { children: [
      /* @__PURE__ */ jsx5(
        "input",
        {
          type: "checkbox",
          checked: column.getIsVisible(),
          onChange: column.getToggleVisibilityHandler()
        }
      ),
      typeof column.columnDef.header === "string" ? column.columnDef.header : column.id
    ] }, column.id)) }),
    /* @__PURE__ */ jsxs4("table", { children: [
      /* @__PURE__ */ jsx5("thead", { children: headerGroups.map((headerGroup) => /* @__PURE__ */ jsx5("tr", { children: headerGroup.headers.map((header) => {
        const canSort = header.column.getCanSort();
        const sorted = header.column.getIsSorted();
        return /* @__PURE__ */ jsxs4(
          "th",
          {
            scope: "col",
            class: canSort ? "sortable" : void 0,
            "aria-sort": sorted === "asc" ? "ascending" : sorted === "desc" ? "descending" : void 0,
            onClick: canSort ? header.column.getToggleSortingHandler() : void 0,
            children: [
              renderHeader(header),
              canSort && /* @__PURE__ */ jsx5("span", { class: "sort-icon", children: sorted === "desc" ? " \u25BC" : sorted === "asc" ? " \u25B2" : "" })
            ]
          },
          header.id
        );
      }) }, headerGroup.id)) }),
      /* @__PURE__ */ jsx5("tbody", { children: rows.map((row) => /* @__PURE__ */ jsx5("tr", { children: row.getVisibleCells().map((cell) => /* @__PURE__ */ jsx5("td", { children: renderCell(cell) }, cell.id)) }, row.id)) })
    ] }),
    pageSize && /* @__PURE__ */ jsxs4(
      "div",
      {
        style: {
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          marginTop: "12px",
          fontSize: "12px",
          color: "var(--muted)"
        },
        children: [
          /* @__PURE__ */ jsx5("span", { children: table.getRowCount() > 0 ? `Showing ${pagination.pageIndex * pagination.pageSize + 1}\u2013${Math.min(
            (pagination.pageIndex + 1) * pagination.pageSize,
            table.getRowCount()
          )} of ${table.getRowCount()}` : "No sessions" }),
          /* @__PURE__ */ jsxs4("div", { style: { display: "flex", gap: "6px" }, children: [
            /* @__PURE__ */ jsx5(
              "button",
              {
                class: "filter-btn",
                disabled: !table.getCanPreviousPage(),
                onClick: () => table.previousPage(),
                children: "\xAB Prev"
              }
            ),
            /* @__PURE__ */ jsx5(
              "button",
              {
                class: "filter-btn",
                disabled: !table.getCanNextPage(),
                onClick: () => table.nextPage(),
                children: "Next \xBB"
              }
            )
          ] })
        ]
      }
    )
  ] });
}

// src/ui/components/EntrypointTable.tsx
import { jsx as jsx6 } from "preact/jsx-runtime";
var columns = [
  {
    accessorKey: "entrypoint",
    header: "Entrypoint",
    cell: ({ getValue }) => /* @__PURE__ */ jsx6("span", { class: "model-tag", children: String(getValue()) })
  },
  {
    accessorKey: "sessions",
    header: "Sessions",
    cell: ({ getValue }) => /* @__PURE__ */ jsx6("span", { class: "num", children: getValue() })
  },
  {
    accessorKey: "turns",
    header: "Turns",
    cell: ({ getValue }) => /* @__PURE__ */ jsx6("span", { class: "num", children: fmt(getValue()) })
  },
  {
    accessorKey: "input",
    header: "Input",
    cell: ({ getValue }) => /* @__PURE__ */ jsx6("span", { class: "num", children: fmt(getValue()) })
  },
  {
    accessorKey: "output",
    header: "Output",
    cell: ({ getValue }) => /* @__PURE__ */ jsx6("span", { class: "num", children: fmt(getValue()) })
  }
];
function EntrypointTable({ data }) {
  if (!data.length) return null;
  return /* @__PURE__ */ jsx6(DataTable, { columns, data, title: "Usage by Entrypoint" });
}

// src/ui/components/ServiceTiers.tsx
import { jsx as jsx7 } from "preact/jsx-runtime";
var columns2 = [
  { accessorKey: "service_tier", header: "Tier" },
  { accessorKey: "inference_geo", header: "Region" },
  {
    accessorKey: "turns",
    header: "Turns",
    cell: ({ getValue }) => /* @__PURE__ */ jsx7("span", { class: "num", children: fmt(getValue()) })
  }
];
function ServiceTiersTable({ data }) {
  if (!data.length) return null;
  return /* @__PURE__ */ jsx7(DataTable, { columns: columns2, data, title: "Service Tiers" });
}

// src/ui/components/ToolUsageTable.tsx
import { jsx as jsx8, jsxs as jsxs5 } from "preact/jsx-runtime";
var columns3 = [
  {
    accessorKey: "tool_name",
    header: "Tool",
    cell: ({ row }) => {
      const cat = row.original.category;
      const badge = cat === "mcp" ? "mcp" : "builtin";
      return /* @__PURE__ */ jsxs5("span", { children: [
        /* @__PURE__ */ jsx8("span", { class: `model-tag ${badge}`, children: cat }),
        " ",
        row.original.tool_name
      ] });
    }
  },
  {
    accessorKey: "mcp_server",
    header: "MCP Server",
    cell: ({ getValue }) => {
      const v2 = getValue();
      return v2 ? /* @__PURE__ */ jsx8("span", { class: "dim", children: v2 }) : /* @__PURE__ */ jsx8("span", { class: "dim", children: "--" });
    }
  },
  {
    accessorKey: "invocations",
    header: "Calls",
    cell: ({ getValue }) => /* @__PURE__ */ jsx8("span", { class: "num", children: fmt(getValue()) })
  },
  {
    accessorKey: "turns_used",
    header: "Turns",
    cell: ({ getValue }) => /* @__PURE__ */ jsx8("span", { class: "num", children: fmt(getValue()) })
  },
  {
    accessorKey: "sessions_used",
    header: "Sessions",
    cell: ({ getValue }) => /* @__PURE__ */ jsx8("span", { class: "num", children: fmt(getValue()) })
  },
  {
    accessorKey: "errors",
    header: "Errors",
    cell: ({ row }) => {
      const e3 = row.original.errors;
      if (!e3) return /* @__PURE__ */ jsx8("span", { class: "dim", children: "0" });
      const pct = row.original.invocations > 0 ? (e3 / row.original.invocations * 100).toFixed(1) : "0";
      return /* @__PURE__ */ jsxs5("span", { class: "num", style: { color: "var(--red)" }, children: [
        e3,
        " (",
        pct,
        "%)"
      ] });
    }
  }
];
function ToolUsageTable({ data }) {
  if (!data.length) return null;
  return /* @__PURE__ */ jsx8(DataTable, { columns: columns3, data, title: "Tool Usage" });
}

// src/ui/components/McpSummaryTable.tsx
import { jsx as jsx9 } from "preact/jsx-runtime";
var columns4 = [
  {
    accessorKey: "server",
    header: "MCP Server",
    cell: ({ getValue }) => /* @__PURE__ */ jsx9("span", { class: "model-tag mcp", children: String(getValue()) })
  },
  {
    accessorKey: "tools_used",
    header: "Tools",
    cell: ({ getValue }) => /* @__PURE__ */ jsx9("span", { class: "num", children: getValue() })
  },
  {
    accessorKey: "invocations",
    header: "Calls",
    cell: ({ getValue }) => /* @__PURE__ */ jsx9("span", { class: "num", children: fmt(getValue()) })
  },
  {
    accessorKey: "sessions_used",
    header: "Sessions",
    cell: ({ getValue }) => /* @__PURE__ */ jsx9("span", { class: "num", children: fmt(getValue()) })
  }
];
function McpSummaryTable({ data }) {
  if (!data.length) return null;
  return /* @__PURE__ */ jsx9(DataTable, { columns: columns4, data, title: "MCP Server Usage" });
}

// src/ui/components/BranchTable.tsx
import { jsx as jsx10 } from "preact/jsx-runtime";
var columns5 = [
  {
    accessorKey: "branch",
    header: "Branch",
    cell: ({ getValue }) => /* @__PURE__ */ jsx10("span", { class: "model-tag", children: String(getValue()) })
  },
  {
    accessorKey: "sessions",
    header: "Sessions",
    cell: ({ getValue }) => /* @__PURE__ */ jsx10("span", { class: "num", children: getValue() })
  },
  {
    accessorKey: "turns",
    header: "Turns",
    cell: ({ getValue }) => /* @__PURE__ */ jsx10("span", { class: "num", children: fmt(getValue()) })
  },
  {
    accessorKey: "input",
    header: "Input",
    cell: ({ getValue }) => /* @__PURE__ */ jsx10("span", { class: "num", children: fmt(getValue()) })
  },
  {
    accessorKey: "output",
    header: "Output",
    cell: ({ getValue }) => /* @__PURE__ */ jsx10("span", { class: "num", children: fmt(getValue()) })
  },
  {
    accessorKey: "cost",
    header: "Est. Cost",
    cell: ({ getValue }) => /* @__PURE__ */ jsx10("span", { class: "cost", children: fmtCost(getValue()) })
  }
];
function BranchTable({ data }) {
  if (!data.length) return null;
  return /* @__PURE__ */ jsx10(DataTable, { columns: columns5, data, title: "Usage by Git Branch" });
}

// src/ui/components/VersionTable.tsx
import { jsx as jsx11 } from "preact/jsx-runtime";
var columns6 = [
  {
    accessorKey: "version",
    header: "Version",
    cell: ({ getValue }) => /* @__PURE__ */ jsx11("span", { class: "model-tag", children: String(getValue()) })
  },
  {
    accessorKey: "turns",
    header: "Turns",
    cell: ({ getValue }) => /* @__PURE__ */ jsx11("span", { class: "num", children: fmt(getValue()) })
  },
  {
    accessorKey: "sessions",
    header: "Sessions",
    cell: ({ getValue }) => /* @__PURE__ */ jsx11("span", { class: "num", children: getValue() })
  }
];
function VersionTable({ data }) {
  if (!data.length) return null;
  return /* @__PURE__ */ jsx11(DataTable, { columns: columns6, data, title: "Claude Code Versions" });
}

// src/ui/components/HourlyChart.tsx
import { jsx as jsx12, jsxs as jsxs6 } from "preact/jsx-runtime";
function HourlyChart({ data }) {
  if (!data.length) return null;
  const maxTurns = Math.max(...data.map((d3) => d3.turns), 1);
  return /* @__PURE__ */ jsxs6("div", { children: [
    /* @__PURE__ */ jsx12("h3", { style: { margin: "0 0 12px", fontSize: "13px", fontWeight: 600, letterSpacing: "0.02em", textTransform: "uppercase", color: "var(--text-secondary)" }, children: "Activity by Hour of Day" }),
    /* @__PURE__ */ jsx12("div", { style: { display: "flex", alignItems: "flex-end", gap: "2px", height: "80px" }, children: Array.from({ length: 24 }, (_3, h3) => {
      const row = data.find((d3) => d3.hour === h3);
      const turns = row?.turns ?? 0;
      const pct = turns / maxTurns * 100;
      return /* @__PURE__ */ jsx12(
        "div",
        {
          title: `${h3}:00 -- ${fmt(turns)} turns`,
          style: {
            flex: 1,
            height: `${Math.max(pct, 2)}%`,
            background: turns > 0 ? "var(--accent)" : "var(--border)",
            borderRadius: "2px 2px 0 0",
            opacity: turns > 0 ? 0.6 + pct / 100 * 0.4 : 0.3
          }
        },
        h3
      );
    }) }),
    /* @__PURE__ */ jsx12("div", { style: { display: "flex", gap: "2px", marginTop: "4px" }, children: [0, 6, 12, 18, 23].map((h3) => /* @__PURE__ */ jsxs6("span", { class: "muted", style: { flex: 1, fontSize: "9px", textAlign: h3 === 0 ? "left" : h3 === 23 ? "right" : "center" }, children: [
      h3,
      ":00"
    ] }, h3)) })
  ] });
}

// src/ui/components/SessionsTable.tsx
import { useMemo } from "preact/hooks";
import { Fragment as Fragment2, jsx as jsx13, jsxs as jsxs7 } from "preact/jsx-runtime";
var defaultSort = [{ id: "last", desc: true }];
function useSessionColumns() {
  return useMemo(
    () => [
      {
        id: "session",
        accessorKey: "session_id",
        header: "Session",
        enableSorting: false,
        cell: (info) => {
          const row = info.row.original;
          const title = row.title;
          return /* @__PURE__ */ jsx13("span", { class: "muted", style: { fontFamily: "monospace" }, title: title || void 0, children: title || /* @__PURE__ */ jsxs7(Fragment2, { children: [
            info.getValue(),
            "\u2026"
          ] }) });
        }
      },
      {
        id: "project",
        accessorKey: "project",
        header: "Project",
        enableSorting: false
      },
      {
        id: "last",
        accessorKey: "last",
        header: "Last Active",
        cell: (info) => /* @__PURE__ */ jsx13("span", { class: "muted", children: info.getValue() })
      },
      {
        id: "duration_min",
        accessorKey: "duration_min",
        header: "Duration",
        cell: (info) => /* @__PURE__ */ jsxs7("span", { class: "muted", children: [
          info.getValue(),
          "m"
        ] })
      },
      {
        id: "model",
        accessorKey: "model",
        header: "Model",
        enableSorting: false,
        cell: (info) => /* @__PURE__ */ jsx13("span", { class: "model-tag", children: info.getValue() })
      },
      {
        id: "turns",
        accessorKey: "turns",
        header: "Turns",
        cell: (info) => {
          const row = info.row.original;
          return /* @__PURE__ */ jsxs7("span", { class: "num", children: [
            fmt(info.getValue()),
            row.subagent_count > 0 && /* @__PURE__ */ jsxs7("span", { class: "muted", style: { fontSize: "10px" }, children: [
              " ",
              "(",
              row.subagent_count,
              " agents)"
            ] })
          ] });
        }
      },
      {
        id: "input",
        accessorKey: "input",
        header: "Input",
        cell: (info) => /* @__PURE__ */ jsx13("span", { class: "num", children: fmt(info.getValue()) })
      },
      {
        id: "output",
        accessorKey: "output",
        header: "Output",
        cell: (info) => /* @__PURE__ */ jsx13("span", { class: "num", children: fmt(info.getValue()) })
      },
      {
        id: "cost",
        accessorKey: "cost",
        header: "Est. Cost",
        cell: (info) => {
          const row = info.row.original;
          return row.is_billable ? /* @__PURE__ */ jsx13("span", { class: "cost", children: fmtCost(info.getValue()) }) : /* @__PURE__ */ jsx13("span", { class: "cost-na", children: "n/a" });
        }
      },
      {
        id: "cache_hit_ratio",
        accessorKey: "cache_hit_ratio",
        header: "Cache %",
        cell: (info) => {
          const v2 = info.getValue();
          return /* @__PURE__ */ jsxs7("span", { class: "num", children: [
            (v2 * 100).toFixed(0),
            "%"
          ] });
        }
      },
      {
        id: "tokens_per_min",
        accessorKey: "tokens_per_min",
        header: "Tok/min",
        cell: (info) => {
          const v2 = info.getValue();
          return /* @__PURE__ */ jsx13("span", { class: "num", children: v2 > 0 ? fmt(Math.round(v2)) : "--" });
        }
      }
    ],
    []
  );
}
function SessionsTable({ onExportCSV }) {
  const columns7 = useSessionColumns();
  const data = lastFilteredSessions.value;
  return /* @__PURE__ */ jsx13(
    DataTable,
    {
      columns: columns7,
      data,
      title: "Recent Sessions",
      exportFn: onExportCSV,
      pageSize: SESSIONS_PAGE_SIZE,
      defaultSort,
      enableColumnVisibility: true
    }
  );
}

// src/ui/components/ModelCostTable.tsx
import { useMemo as useMemo2 } from "preact/hooks";
import { jsx as jsx14 } from "preact/jsx-runtime";
var defaultSort2 = [{ id: "cost", desc: true }];
function useModelColumns() {
  return useMemo2(
    () => [
      {
        id: "model",
        accessorKey: "model",
        header: "Model",
        enableSorting: false,
        cell: (info) => /* @__PURE__ */ jsx14("span", { class: "model-tag", children: info.getValue() })
      },
      {
        id: "turns",
        accessorKey: "turns",
        header: "Turns",
        cell: (info) => /* @__PURE__ */ jsx14("span", { class: "num", children: fmt(info.getValue()) })
      },
      {
        id: "input",
        accessorKey: "input",
        header: "Input",
        cell: (info) => /* @__PURE__ */ jsx14("span", { class: "num", children: fmt(info.getValue()) })
      },
      {
        id: "output",
        accessorKey: "output",
        header: "Output",
        cell: (info) => /* @__PURE__ */ jsx14("span", { class: "num", children: fmt(info.getValue()) })
      },
      {
        id: "cache_read",
        accessorKey: "cache_read",
        header: "Cache Read",
        cell: (info) => /* @__PURE__ */ jsx14("span", { class: "num", children: fmt(info.getValue()) })
      },
      {
        id: "cache_creation",
        accessorKey: "cache_creation",
        header: "Cache Creation",
        cell: (info) => /* @__PURE__ */ jsx14("span", { class: "num", children: fmt(info.getValue()) })
      },
      {
        id: "cost",
        accessorKey: "cost",
        header: "Est. Cost",
        cell: (info) => {
          const row = info.row.original;
          return row.is_billable ? /* @__PURE__ */ jsx14("span", { class: "cost", children: fmtCost(info.getValue()) }) : /* @__PURE__ */ jsx14("span", { class: "cost-na", children: "n/a" });
        }
      }
    ],
    []
  );
}
function ModelCostTable({ byModel }) {
  const columns7 = useModelColumns();
  return /* @__PURE__ */ jsx14(
    DataTable,
    {
      columns: columns7,
      data: byModel,
      title: "Cost by Model",
      defaultSort: defaultSort2
    }
  );
}

// src/ui/components/ProjectCostTable.tsx
import { useMemo as useMemo3 } from "preact/hooks";
import { jsx as jsx15 } from "preact/jsx-runtime";
var defaultSort3 = [{ id: "cost", desc: true }];
function useProjectColumns() {
  return useMemo3(
    () => [
      {
        id: "project",
        accessorKey: "project",
        header: "Project",
        enableSorting: false
      },
      {
        id: "sessions",
        accessorKey: "sessions",
        header: "Sessions",
        cell: (info) => /* @__PURE__ */ jsx15("span", { class: "num", children: info.getValue() })
      },
      {
        id: "turns",
        accessorKey: "turns",
        header: "Turns",
        cell: (info) => /* @__PURE__ */ jsx15("span", { class: "num", children: fmt(info.getValue()) })
      },
      {
        id: "input",
        accessorKey: "input",
        header: "Input",
        cell: (info) => /* @__PURE__ */ jsx15("span", { class: "num", children: fmt(info.getValue()) })
      },
      {
        id: "output",
        accessorKey: "output",
        header: "Output",
        cell: (info) => /* @__PURE__ */ jsx15("span", { class: "num", children: fmt(info.getValue()) })
      },
      {
        id: "cost",
        accessorKey: "cost",
        header: "Est. Cost",
        cell: (info) => /* @__PURE__ */ jsx15("span", { class: "cost", children: fmtCost(info.getValue()) })
      }
    ],
    []
  );
}
function ProjectCostTable({
  byProject,
  onExportCSV
}) {
  const columns7 = useProjectColumns();
  return /* @__PURE__ */ jsx15(
    DataTable,
    {
      columns: columns7,
      data: byProject,
      title: "Cost by Project",
      exportFn: onExportCSV,
      defaultSort: defaultSort3
    }
  );
}

// src/ui/components/ApexChart.tsx
import { useRef as useRef2, useEffect as useEffect2, useMemo as useMemo4 } from "preact/hooks";
import { jsx as jsx16 } from "preact/jsx-runtime";
function ApexChart({ options, id }) {
  const ref = useRef2(null);
  const chartRef = useRef2(null);
  const optionsKey = useMemo4(
    () => JSON.stringify(options, (_key, val) => typeof val === "function" ? void 0 : val),
    [options]
  );
  useEffect2(() => {
    if (chartRef.current) chartRef.current.destroy();
    if (ref.current && options) {
      chartRef.current = new ApexCharts(ref.current, options);
      chartRef.current.render();
    }
    return () => {
      chartRef.current?.destroy();
      chartRef.current = null;
    };
  }, [optionsKey]);
  return /* @__PURE__ */ jsx16("div", { ref, id, style: { width: "100%", height: "100%" } });
}

// src/ui/components/DailyChart.tsx
import { jsx as jsx17 } from "preact/jsx-runtime";
function DailyChart({ daily }) {
  const options = {
    chart: {
      type: "area",
      height: "100%",
      stacked: true,
      background: "transparent",
      toolbar: { show: false },
      fontFamily: "inherit"
    },
    theme: { mode: apexThemeMode() },
    series: [
      { name: "Input", data: daily.map((d3) => d3.input) },
      { name: "Output", data: daily.map((d3) => d3.output) },
      { name: "Cache Read", data: daily.map((d3) => d3.cache_read) },
      { name: "Cache Creation", data: daily.map((d3) => d3.cache_creation) }
    ],
    colors: [TOKEN_COLORS.input, TOKEN_COLORS.output, TOKEN_COLORS.cache_read, TOKEN_COLORS.cache_creation],
    fill: {
      type: "gradient",
      gradient: {
        shadeIntensity: 1,
        opacityFrom: 0.4,
        opacityTo: 0.05,
        stops: [0, 95, 100]
      }
    },
    stroke: { curve: "smooth", width: 2 },
    xaxis: {
      categories: daily.map((d3) => d3.day),
      labels: { rotate: -45, maxHeight: 60 },
      tickAmount: Math.min(daily.length, RANGE_TICKS[selectedRange.value])
    },
    yaxis: { labels: { formatter: (v2) => fmt(v2) } },
    legend: { position: "top", fontSize: "11px" },
    dataLabels: { enabled: false },
    tooltip: { y: { formatter: (v2) => fmt(v2) + " tokens" } },
    grid: { borderColor: cssVar("--chart-grid"), strokeDashArray: 3 }
  };
  return /* @__PURE__ */ jsx17(ApexChart, { options, id: "chart-daily" });
}

// src/ui/components/ModelChart.tsx
import { jsx as jsx18 } from "preact/jsx-runtime";
function ModelChart({ byModel }) {
  if (!byModel.length) return null;
  const options = {
    chart: { type: "donut", height: "100%", background: "transparent", fontFamily: "inherit" },
    theme: { mode: apexThemeMode() },
    series: byModel.map((m2) => m2.input + m2.output),
    labels: byModel.map((m2) => m2.model),
    colors: MODEL_COLORS.slice(0, byModel.length),
    legend: { position: "bottom", fontSize: "11px" },
    dataLabels: { enabled: false },
    tooltip: { y: { formatter: (v2) => fmt(v2) + " tokens" } },
    stroke: { width: 2, colors: [cssVar("--card")] },
    plotOptions: { pie: { donut: { size: "60%" } } }
  };
  return /* @__PURE__ */ jsx18(ApexChart, { options, id: "chart-model" });
}

// src/ui/components/ProjectChart.tsx
import { jsx as jsx19 } from "preact/jsx-runtime";
function ProjectChart({ byProject }) {
  const top = byProject.slice(0, 10);
  if (!top.length) return null;
  const options = {
    chart: {
      type: "bar",
      height: "100%",
      background: "transparent",
      toolbar: { show: false },
      fontFamily: "inherit"
    },
    theme: { mode: apexThemeMode() },
    series: [
      { name: "Input", data: top.map((p3) => p3.input) },
      { name: "Output", data: top.map((p3) => p3.output) }
    ],
    colors: [TOKEN_COLORS.input, TOKEN_COLORS.output],
    plotOptions: { bar: { horizontal: true, barHeight: "60%" } },
    xaxis: {
      categories: top.map((p3) => p3.project.length > 22 ? "\u2026" + p3.project.slice(-20) : p3.project),
      labels: { formatter: (v2) => fmt(v2) }
    },
    yaxis: { labels: { maxWidth: 160 } },
    legend: { position: "top", fontSize: "11px" },
    dataLabels: { enabled: false },
    tooltip: { y: { formatter: (v2) => fmt(v2) + " tokens" } },
    grid: { borderColor: cssVar("--chart-grid") }
  };
  return /* @__PURE__ */ jsx19(ApexChart, { options, id: "chart-project" });
}

// src/ui/components/Sparkline.tsx
import { jsx as jsx20, jsxs as jsxs8 } from "preact/jsx-runtime";
function Sparkline({ daily }) {
  const last7 = daily.slice(-7);
  if (last7.length < 2) return null;
  const options = {
    chart: {
      type: "line",
      height: 30,
      width: 120,
      sparkline: { enabled: true },
      background: "transparent",
      fontFamily: "inherit"
    },
    series: [{ data: last7.map((d3) => d3.input + d3.output) }],
    stroke: { width: 1.5, curve: "smooth" },
    colors: [cssVar("--accent")],
    tooltip: { enabled: false }
  };
  return /* @__PURE__ */ jsxs8("div", { children: [
    /* @__PURE__ */ jsx20("div", { class: "sub", style: { marginBottom: "4px" }, children: "7-day trend" }),
    /* @__PURE__ */ jsx20(ApexChart, { options })
  ] });
}

// src/ui/lib/csv.ts
function csvField(val) {
  const s2 = String(val);
  const needsPrefix = /^[=+\-@\t\r]/.test(s2);
  const escaped = needsPrefix ? "'" + s2 : s2;
  if (escaped.includes(",") || escaped.includes('"') || escaped.includes("\n")) {
    return '"' + escaped.replace(/"/g, '""') + '"';
  }
  return escaped;
}
function csvTimestamp() {
  const d3 = /* @__PURE__ */ new Date();
  return d3.getFullYear() + "-" + String(d3.getMonth() + 1).padStart(2, "0") + "-" + String(d3.getDate()).padStart(2, "0") + "_" + String(d3.getHours()).padStart(2, "0") + String(d3.getMinutes()).padStart(2, "0");
}
function downloadCSV(reportType, header, rows) {
  const lines = [header.map(csvField).join(",")];
  for (const row of rows) lines.push(row.map(csvField).join(","));
  const blob = new Blob([lines.join("\n")], { type: "text/csv;charset=utf-8;" });
  const a2 = document.createElement("a");
  a2.href = URL.createObjectURL(blob);
  a2.download = reportType + "_" + csvTimestamp() + ".csv";
  a2.click();
  setTimeout(() => URL.revokeObjectURL(a2.href), 1e3);
}

// src/ui/lib/rescan.ts
function createTriggerRescan({
  button,
  fetchImpl,
  loadData: loadData2,
  showError: showError2,
  setTimer,
  logError = () => void 0
}) {
  return async function triggerRescan2() {
    button.disabled = true;
    button.textContent = "\u21BB Scanning...";
    try {
      const resp = await fetchImpl("/api/rescan", { method: "POST" });
      if (!resp.ok) {
        showError2(`Rescan failed: HTTP ${resp.status} ${resp.statusText}`);
        button.textContent = "\u21BB Rescan (failed)";
        return;
      }
      const data = await resp.json();
      button.textContent = "\u21BB Rescan (" + data.new + " new, " + data.updated + " updated)";
      await loadData2(true);
    } catch (error) {
      const msg = error instanceof Error ? error.message : String(error);
      showError2("Rescan failed: " + msg);
      button.textContent = "\u21BB Rescan (error)";
      logError(error);
    } finally {
      setTimer(() => {
        button.textContent = "\u21BB Rescan";
        button.disabled = false;
      }, 3e3);
    }
  };
}

// src/ui/lib/theme.ts
function getTheme() {
  const stored = localStorage.getItem("theme");
  if (stored === "light" || stored === "dark") return stored;
  return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
}

// src/ui/app.tsx
import { jsx as jsx21 } from "preact/jsx-runtime";
function applyTheme(theme) {
  if (theme === "light") {
    document.documentElement.setAttribute("data-theme", "light");
  } else {
    document.documentElement.removeAttribute("data-theme");
  }
  const icon = document.getElementById("theme-icon");
  if (icon) icon.innerHTML = theme === "dark" ? '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>' : '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>';
  if (rawData.value) applyFilter();
}
function toggleTheme() {
  const current = document.documentElement.getAttribute("data-theme") === "light" ? "light" : "dark";
  const next = current === "light" ? "dark" : "light";
  localStorage.setItem("theme", next);
  applyTheme(next);
}
applyTheme(getTheme());
var previousSessionPercent = null;
var loadDataInFlight = false;
var loadUsageWindowsInFlight = false;
function isAnthropicModel(model) {
  if (!model) return false;
  const m2 = model.toLowerCase();
  return m2.includes("opus") || m2.includes("sonnet") || m2.includes("haiku");
}
function getRangeCutoff(range) {
  if (range === "all") return null;
  const days = range === "7d" ? 7 : range === "30d" ? 30 : 90;
  const d3 = /* @__PURE__ */ new Date();
  d3.setDate(d3.getDate() - days);
  return d3.toISOString().slice(0, 10);
}
function readURLRange() {
  const p3 = new URLSearchParams(window.location.search).get("range");
  return ["7d", "30d", "90d", "all"].includes(p3) ? p3 : "30d";
}
function setRange(range) {
  selectedRange.value = range;
  document.querySelectorAll(".range-btn").forEach(
    (btn) => btn.classList.toggle("active", btn.dataset.range === range)
  );
  updateURL();
  applyFilter();
}
function modelPriority(m2) {
  const ml = m2.toLowerCase();
  if (ml.includes("opus")) return 0;
  if (ml.includes("sonnet")) return 1;
  if (ml.includes("haiku")) return 2;
  return 3;
}
function readURLModels(allModels) {
  const param = new URLSearchParams(window.location.search).get("models");
  if (!param) return new Set(allModels.filter((m2) => isAnthropicModel(m2)));
  const fromURL = new Set(param.split(",").map((s2) => s2.trim()).filter(Boolean));
  return new Set(allModels.filter((m2) => fromURL.has(m2)));
}
function isDefaultModelSelection(allModels) {
  const billable = allModels.filter((m2) => isAnthropicModel(m2));
  if (selectedModels.value.size !== billable.length) return false;
  return billable.every((m2) => selectedModels.value.has(m2));
}
function buildFilterUI(allModels) {
  const sorted = [...allModels].sort((a2, b3) => {
    const pa = modelPriority(a2), pb = modelPriority(b3);
    return pa !== pb ? pa - pb : a2.localeCompare(b3);
  });
  selectedModels.value = readURLModels(allModels);
  const container = $("model-checkboxes");
  container.innerHTML = sorted.map((m2) => {
    const checked = selectedModels.value.has(m2);
    return `<label class="model-cb-label ${checked ? "checked" : ""}" data-model="${esc(m2)}">
      <input type="checkbox" value="${esc(m2)}" ${checked ? "checked" : ""} onchange="onModelToggle(this)">
      ${esc(m2)}
    </label>`;
  }).join("");
}
function onModelToggle(cb) {
  const label = cb.closest("label");
  const next = new Set(selectedModels.value);
  if (cb.checked) {
    next.add(cb.value);
    label.classList.add("checked");
  } else {
    next.delete(cb.value);
    label.classList.remove("checked");
  }
  selectedModels.value = next;
  updateURL();
  applyFilter();
}
function selectAllModels() {
  const next = new Set(selectedModels.value);
  document.querySelectorAll("#model-checkboxes input").forEach((cb) => {
    cb.checked = true;
    next.add(cb.value);
    cb.closest("label").classList.add("checked");
  });
  selectedModels.value = next;
  updateURL();
  applyFilter();
}
function clearAllModels() {
  document.querySelectorAll("#model-checkboxes input").forEach((cb) => {
    cb.checked = false;
    cb.closest("label").classList.remove("checked");
  });
  selectedModels.value = /* @__PURE__ */ new Set();
  updateURL();
  applyFilter();
}
function onProjectSearch(query) {
  projectSearchQuery.value = query.toLowerCase().trim();
  const clearBtn = document.getElementById("project-clear-btn");
  if (clearBtn) clearBtn.style.display = projectSearchQuery.value ? "" : "none";
  updateURL();
  applyFilter();
}
function clearProjectSearch() {
  projectSearchQuery.value = "";
  const input = document.getElementById("project-search");
  if (input) input.value = "";
  const clearBtn = document.getElementById("project-clear-btn");
  if (clearBtn) clearBtn.style.display = "none";
  updateURL();
  applyFilter();
}
function matchesProjectSearch(project) {
  if (!projectSearchQuery.value) return true;
  return project.toLowerCase().includes(projectSearchQuery.value);
}
function updateURL() {
  const allModels = Array.from(document.querySelectorAll("#model-checkboxes input")).map((cb) => cb.value);
  const params = new URLSearchParams();
  if (selectedRange.value !== "30d") params.set("range", selectedRange.value);
  if (!isDefaultModelSelection(allModels)) params.set("models", Array.from(selectedModels.value).join(","));
  if (projectSearchQuery.value) params.set("project", projectSearchQuery.value);
  const search = params.toString() ? "?" + params.toString() : "";
  history.replaceState(null, "", window.location.pathname + search);
}
function applyFilter() {
  if (!rawData.value) return;
  const cutoff = getRangeCutoff(selectedRange.value);
  const filteredDaily = rawData.value.daily_by_model.filter(
    (r3) => selectedModels.value.has(r3.model) && (!cutoff || r3.day >= cutoff)
  );
  const dailyMap = {};
  for (const r3 of filteredDaily) {
    if (!dailyMap[r3.day]) dailyMap[r3.day] = { day: r3.day, input: 0, output: 0, cache_read: 0, cache_creation: 0 };
    const d3 = dailyMap[r3.day];
    d3.input += r3.input;
    d3.output += r3.output;
    d3.cache_read += r3.cache_read;
    d3.cache_creation += r3.cache_creation;
  }
  const daily = Object.values(dailyMap).sort((a2, b3) => a2.day.localeCompare(b3.day));
  const modelMap = {};
  for (const r3 of filteredDaily) {
    if (!modelMap[r3.model]) modelMap[r3.model] = { model: r3.model, input: 0, output: 0, cache_read: 0, cache_creation: 0, turns: 0, sessions: 0, cost: 0, is_billable: r3.cost > 0 || isAnthropicModel(r3.model) };
    const m2 = modelMap[r3.model];
    m2.input += r3.input;
    m2.output += r3.output;
    m2.cache_read += r3.cache_read;
    m2.cache_creation += r3.cache_creation;
    m2.turns += r3.turns;
    m2.cost += r3.cost;
  }
  const filteredSessions = rawData.value.sessions_all.filter(
    (s2) => selectedModels.value.has(s2.model) && (!cutoff || s2.last_date >= cutoff) && matchesProjectSearch(s2.project)
  );
  for (const s2 of filteredSessions) {
    if (modelMap[s2.model]) modelMap[s2.model].sessions++;
  }
  const byModel = Object.values(modelMap).sort((a2, b3) => b3.input + b3.output - (a2.input + a2.output));
  const projMap = {};
  for (const s2 of filteredSessions) {
    if (!projMap[s2.project]) projMap[s2.project] = { project: s2.project, input: 0, output: 0, cache_read: 0, cache_creation: 0, turns: 0, sessions: 0, cost: 0 };
    const p3 = projMap[s2.project];
    p3.input += s2.input;
    p3.output += s2.output;
    p3.cache_read += s2.cache_read;
    p3.cache_creation += s2.cache_creation;
    p3.turns += s2.turns;
    p3.sessions++;
    p3.cost += s2.cost;
  }
  const byProject = Object.values(projMap).sort((a2, b3) => b3.input + b3.output - (a2.input + a2.output));
  const totals = {
    sessions: filteredSessions.length,
    turns: byModel.reduce((s2, m2) => s2 + m2.turns, 0),
    input: byModel.reduce((s2, m2) => s2 + m2.input, 0),
    output: byModel.reduce((s2, m2) => s2 + m2.output, 0),
    cache_read: byModel.reduce((s2, m2) => s2 + m2.cache_read, 0),
    cache_creation: byModel.reduce((s2, m2) => s2 + m2.cache_creation, 0),
    cost: filteredSessions.reduce((s2, sess) => s2 + sess.cost, 0)
  };
  $("daily-chart-title").textContent = "Daily Token Usage \u2014 " + RANGE_LABELS[selectedRange.value];
  renderStats(totals);
  renderCostSparkline(daily);
  renderDailyChart(daily);
  renderModelChart(byModel);
  renderProjectChart(byProject);
  lastFilteredSessions.value = filteredSessions;
  lastByProject.value = byProject;
  render(/* @__PURE__ */ jsx21(ModelCostTable, { byModel }), $("model-cost-mount"));
  render(/* @__PURE__ */ jsx21(SessionsTable, { onExportCSV: exportSessionsCSV }), $("sessions-mount"));
  render(/* @__PURE__ */ jsx21(ProjectCostTable, { byProject: lastByProject.value.slice(0, 30), onExportCSV: exportProjectsCSV }), $("project-cost-mount"));
}
function renderStats(t3) {
  render(/* @__PURE__ */ jsx21(StatsCards, { totals: t3 }), $("stats-row"));
}
function renderDailyChart(daily) {
  const container = document.getElementById("chart-daily");
  render(/* @__PURE__ */ jsx21(DailyChart, { daily }), container);
}
function renderModelChart(byModel) {
  const container = document.getElementById("chart-model");
  render(/* @__PURE__ */ jsx21(ModelChart, { byModel }), container);
}
function renderProjectChart(byProject) {
  const container = document.getElementById("chart-project");
  render(/* @__PURE__ */ jsx21(ProjectChart, { byProject }), container);
}
function exportSessionsCSV() {
  const header = ["Session", "Project", "Last Active", "Duration (min)", "Model", "Turns", "Input", "Output", "Cache Read", "Cache Creation", "Est. Cost"];
  const rows = lastFilteredSessions.value.map((s2) => {
    const cost = s2.cost;
    return [s2.session_id, s2.project, s2.last, s2.duration_min, s2.model, s2.turns, s2.input, s2.output, s2.cache_read, s2.cache_creation, cost.toFixed(4)];
  });
  downloadCSV("sessions", header, rows);
}
function exportProjectsCSV() {
  const header = ["Project", "Sessions", "Turns", "Input", "Output", "Cache Read", "Cache Creation", "Est. Cost"];
  const rows = lastByProject.value.map(
    (p3) => [p3.project, p3.sessions, p3.turns, p3.input, p3.output, p3.cache_read, p3.cache_creation, p3.cost.toFixed(4)]
  );
  downloadCSV("projects", header, rows);
}
function renderWindowCard(label, w3) {
  const pct = Math.min(100, w3.used_percent);
  const color = progressColor(pct);
  const resetText = w3.resets_in_minutes != null ? `Resets in ${fmtResetTime(w3.resets_in_minutes)}` : "";
  return `<div class="stat-card">
    <div class="label">${esc(label)}</div>
    <div class="value" style="font-size:18px;color:${color}">${pct.toFixed(1)}%</div>
    <div style="background:var(--border);border-radius:4px;height:6px;margin:6px 0">
      <div style="background:${color};height:100%;border-radius:4px;width:${pct}%;transition:width 0.3s"></div>
    </div>
    <div class="sub">${esc(resetText)}</div>
  </div>`;
}
function renderUsageWindows(data) {
  const container = $("usage-windows");
  if (!container) return;
  if (!data.available) {
    const badge2 = $("plan-badge");
    if (badge2) badge2.style.display = "none";
    if (data.error) {
      container.style.display = "";
      container.innerHTML = `<div class="stat-card">
        <div class="label">Rate Windows</div>
        <div class="value" style="font-size:16px">Unavailable</div>
        <div class="sub">${esc(data.error)}</div>
      </div>`;
    } else {
      container.innerHTML = "";
      container.style.display = "none";
    }
    return;
  }
  container.style.display = "";
  let cards = "";
  if (data.session) cards += renderWindowCard("Session (5h)", data.session);
  if (data.weekly) cards += renderWindowCard("Weekly", data.weekly);
  if (data.weekly_opus) cards += renderWindowCard("Weekly Opus", data.weekly_opus);
  if (data.weekly_sonnet) cards += renderWindowCard("Weekly Sonnet", data.weekly_sonnet);
  if (data.budget) {
    const b3 = data.budget;
    const pct = Math.min(100, b3.utilization);
    const color = progressColor(pct);
    cards += `<div class="stat-card">
      <div class="label">Monthly Budget</div>
      <div class="value" style="font-size:18px;color:${color}">$${b3.used.toFixed(2)} / $${b3.limit.toFixed(2)}</div>
      <div style="background:var(--border);border-radius:4px;height:6px;margin:6px 0">
        <div style="background:${color};height:100%;border-radius:4px;width:${pct}%;transition:width 0.3s"></div>
      </div>
      <div class="sub">${esc(b3.currency)}</div>
    </div>`;
  }
  container.innerHTML = cards;
  if (data.session) {
    const currentPercent = 100 - data.session.used_percent;
    if (previousSessionPercent !== null) {
      if (previousSessionPercent > 0.01 && currentPercent <= 0.01) {
        showError("Session depleted \u2014 resets in " + fmtResetTime(data.session.resets_in_minutes));
      } else if (previousSessionPercent <= 0.01 && currentPercent > 0.01) {
        showSuccess("Session restored");
      }
    }
    previousSessionPercent = currentPercent;
  }
  const badge = $("plan-badge");
  if (badge && data.identity?.plan) {
    badge.textContent = data.identity.plan.charAt(0).toUpperCase() + data.identity.plan.slice(1);
    badge.style.display = "";
  } else if (badge) {
    badge.style.display = "none";
  }
}
function renderSubagentSummary(summary) {
  const container = $("subagent-summary");
  if (!container) return;
  if (summary.subagent_turns === 0) {
    container.style.display = "none";
    render(null, container);
    return;
  }
  container.style.display = "";
  render(/* @__PURE__ */ jsx21(SubagentSummary, { summary }), container);
}
function renderEntrypointBreakdown(data) {
  const container = $("entrypoint-breakdown");
  if (!container) return;
  if (!data.length) {
    container.style.display = "none";
    render(null, container);
    return;
  }
  container.style.display = "";
  render(/* @__PURE__ */ jsx21(EntrypointTable, { data }), container);
}
function renderServiceTiers(data) {
  const container = $("service-tiers");
  if (!container) return;
  if (!data.length) {
    container.style.display = "none";
    render(null, container);
    return;
  }
  container.style.display = "";
  render(/* @__PURE__ */ jsx21(ServiceTiersTable, { data }), container);
}
function renderToolSummary(data) {
  const container = $("tool-summary");
  if (!container) return;
  if (!data.length) {
    container.style.display = "none";
    render(null, container);
    return;
  }
  container.style.display = "";
  render(/* @__PURE__ */ jsx21(ToolUsageTable, { data }), container);
}
function renderMcpSummary(data) {
  const container = $("mcp-summary");
  if (!container) return;
  if (!data.length) {
    container.style.display = "none";
    render(null, container);
    return;
  }
  container.style.display = "";
  render(/* @__PURE__ */ jsx21(McpSummaryTable, { data }), container);
}
function renderBranchSummary(data) {
  const container = $("branch-summary");
  if (!container) return;
  if (!data.length) {
    container.style.display = "none";
    render(null, container);
    return;
  }
  container.style.display = "";
  render(/* @__PURE__ */ jsx21(BranchTable, { data }), container);
}
function renderVersionSummary(data) {
  const container = $("version-summary");
  if (!container) return;
  if (!data.length) {
    container.style.display = "none";
    render(null, container);
    return;
  }
  container.style.display = "";
  render(/* @__PURE__ */ jsx21(VersionTable, { data }), container);
}
function renderHourlyChart(data) {
  const container = $("hourly-chart");
  if (!container) return;
  if (!data.length) {
    container.style.display = "none";
    render(null, container);
    return;
  }
  container.style.display = "";
  render(/* @__PURE__ */ jsx21(HourlyChart, { data }), container);
}
function renderCostSparkline(daily) {
  const container = $("cost-sparkline");
  if (!container) return;
  const last7 = daily.slice(-7);
  if (last7.length < 2) {
    container.style.display = "none";
    render(null, container);
    return;
  }
  container.style.display = "";
  render(/* @__PURE__ */ jsx21(Sparkline, { daily }), container);
}
async function loadUsageWindows() {
  if (loadUsageWindowsInFlight) return;
  loadUsageWindowsInFlight = true;
  try {
    const resp = await fetch("/api/usage-windows");
    if (!resp.ok) return;
    const data = await resp.json();
    renderUsageWindows(data);
  } catch {
  } finally {
    loadUsageWindowsInFlight = false;
  }
}
var triggerRescan = createTriggerRescan({
  button: $("rescan-btn"),
  fetchImpl: (input, init) => fetch(input, init),
  loadData,
  showError,
  setTimer: (callback, delayMs) => window.setTimeout(callback, delayMs),
  logError: (error) => console.error(error)
});
function renderLoadingSkeleton() {
  const statsRow = document.getElementById("stats-row");
  if (statsRow && !rawData.value) {
    statsRow.innerHTML = Array.from(
      { length: 7 },
      () => '<div class="skeleton" style="height:80px"></div>'
    ).join("");
  }
}
renderLoadingSkeleton();
async function loadData(force = false) {
  if (loadDataInFlight && !force) return;
  loadDataInFlight = true;
  try {
    const resp = await fetch("/api/data");
    if (!resp.ok) {
      showError(`Failed to load data: HTTP ${resp.status}`);
      return;
    }
    const d3 = await resp.json();
    if (d3.error) {
      document.body.innerHTML = '<div style="padding:40px;color:#f87171;font-family:monospace">' + esc(d3.error) + "</div>";
      return;
    }
    $("meta").textContent = "Updated: " + d3.generated_at + " \xB7 Auto-refresh 30s";
    const isFirstLoad = rawData.value === null;
    rawData.value = d3;
    if (isFirstLoad) {
      selectedRange.value = readURLRange();
      document.querySelectorAll(".range-btn").forEach(
        (btn) => btn.classList.toggle("active", btn.dataset.range === selectedRange.value)
      );
      buildFilterUI(d3.all_models);
      const urlProject = new URLSearchParams(window.location.search).get("project");
      if (urlProject) {
        projectSearchQuery.value = urlProject;
        const input = document.getElementById("project-search");
        if (input) input.value = urlProject;
        const clearBtn = document.getElementById("project-clear-btn");
        if (clearBtn) clearBtn.style.display = "";
      }
    }
    applyFilter();
    if (rawData.value.subagent_summary) renderSubagentSummary(rawData.value.subagent_summary);
    if (rawData.value.entrypoint_breakdown) renderEntrypointBreakdown(rawData.value.entrypoint_breakdown);
    if (rawData.value.service_tiers) renderServiceTiers(rawData.value.service_tiers);
    if (rawData.value.tool_summary) renderToolSummary(rawData.value.tool_summary);
    if (rawData.value.mcp_summary) renderMcpSummary(rawData.value.mcp_summary);
    if (rawData.value.git_branch_summary) renderBranchSummary(rawData.value.git_branch_summary);
    if (rawData.value.version_summary) renderVersionSummary(rawData.value.version_summary);
    if (rawData.value.hourly_distribution) renderHourlyChart(rawData.value.hourly_distribution);
  } catch (e3) {
    console.error(e3);
  } finally {
    loadDataInFlight = false;
  }
}
Object.assign(window, {
  setRange,
  onModelToggle,
  selectAllModels,
  clearAllModels,
  exportSessionsCSV,
  exportProjectsCSV,
  triggerRescan,
  onProjectSearch,
  clearProjectSearch,
  toggleTheme
});
loadData();
setInterval(loadData, 3e4);
loadUsageWindows();
setInterval(loadUsageWindows, 6e4);
var footerEl = document.querySelector("footer");
if (footerEl && footerEl.parentElement) {
  render(/* @__PURE__ */ jsx21(Footer, {}), footerEl.parentElement, footerEl);
}
var toastRoot = document.createElement("div");
document.body.appendChild(toastRoot);
render(/* @__PURE__ */ jsx21(ToastContainer, {}), toastRoot);
