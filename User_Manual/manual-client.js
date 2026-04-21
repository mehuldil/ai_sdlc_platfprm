/* eslint-disable no-var */
(function () {
  var el = document.getElementById("manual-data");
  if (!el) return;

  var data;
  try {
    data = JSON.parse(el.textContent);
  } catch (e) {
    console.error("manual-data JSON parse failed", e);
    return;
  }

  var prefersReducedMotion =
    typeof window.matchMedia === "function" &&
    window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  function escapeHtml(s) {
    return String(s)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function slugify(str) {
    return String(str)
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-|-$/g, "");
  }

  function inlineMd(t) {
    if (!t) return "";
    var s = escapeHtml(t);
    s = s.replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>");
    s = s.replace(/`([^`]+)`/g, "<code>$1</code>");
    s = s.replace(/\[([^\]]+)\]\(([^)]+)\)/g, function (_, label, href) {
      if (/\.md(#|$)/.test(href)) {
        var f = href.replace(/#.*$/, "").replace(/^\.\//, "");
        var base = f.replace(/\.md$/i, "").toLowerCase();
        return '<a href="#doc-' + base + '">' + escapeHtml(label) + "</a>";
      }
      return (
        '<a href="' +
        escapeHtml(href) +
        '" target="_blank" rel="noopener noreferrer">' +
        escapeHtml(label) +
        "</a>"
      );
    });
    return s;
  }

  function mdToHtml(src) {
    var lines = src.replace(/\r\n/g, "\n").split("\n");
    var out = [];
    var inCode = false;
    var codeBuf = [];

    var listStack = [];

    function closeLists() {
      while (listStack.length) {
        out.push(listStack.pop() === "ol" ? "</ol>" : "</ul>");
      }
    }

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i];
      if (/^```/.test(line)) {
        if (!inCode) {
          closeLists();
          inCode = true;
          codeBuf = [];
        } else {
          inCode = false;
          out.push(
            '<div class="code-block-wrap"><pre class="md-pre"><code>' +
              escapeHtml(codeBuf.join("\n")) +
              "</code></pre></div>"
          );
          codeBuf = [];
        }
        continue;
      }
      if (inCode) {
        codeBuf.push(line);
        continue;
      }
      if (/^---+$/.test(line.trim())) {
        closeLists();
        out.push('<hr class="md-hr" />');
        continue;
      }
      var h = /^(#{1,4})\s+(.+)$/.exec(line);
      if (h) {
        closeLists();
        var level = h[1].length;
        out.push(
          "<h" +
            level +
            ' class="md-h' +
            level +
            '" id="' +
            slugify(h[2]) +
            '">' +
            inlineMd(h[2]) +
            "</h" +
            level +
            ">"
        );
        continue;
      }
      var ul = /^[-*]\s+(.+)$/.exec(line);
      if (ul) {
        if (listStack[listStack.length - 1] !== "ul") {
          closeLists();
          out.push("<ul>");
          listStack.push("ul");
        }
        out.push("<li>" + inlineMd(ul[1]) + "</li>");
        continue;
      }
      var ol = /^\d+\.\s+(.+)$/.exec(line);
      if (ol) {
        if (listStack[listStack.length - 1] !== "ol") {
          closeLists();
          out.push("<ol>");
          listStack.push("ol");
        }
        out.push("<li>" + inlineMd(ol[1]) + "</li>");
        continue;
      }
      if (line.trim() === "") {
        closeLists();
        continue;
      }
      var sep = lines[i + 1] || "";
      if (line.indexOf("|") >= 0 && /^\|[\s\-:|]+\|/.test(sep)) {
        closeLists();
        var headCells = line.split("|").filter(function (c) {
          return c.trim() !== "";
        });
        out.push('<div class="table-wrap"><table class="md-table"><thead><tr>');
        headCells.forEach(function (c) {
          out.push("<th>" + inlineMd(c.trim()) + "</th>");
        });
        out.push("</tr></thead><tbody>");
        for (var j = i + 2; j < lines.length; j++) {
          var row = lines[j];
          if (!/^\|/.test(row.trim())) {
            i = j - 1;
            break;
          }
          var cells = row.split("|").filter(function (c) {
            return c.trim() !== "";
          });
          if (!cells.length) continue;
          out.push("<tr>");
          cells.forEach(function (c) {
            out.push("<td>" + inlineMd(c.trim()) + "</td>");
          });
          out.push("</tr>");
        }
        out.push("</tbody></table></div>");
        continue;
      }
      if (/^>\s?/.test(line)) {
        closeLists();
        out.push(
          '<blockquote class="md-quote"><p>' +
            inlineMd(line.replace(/^>\s?/, "")) +
            "</p></blockquote>"
        );
        continue;
      }
      closeLists();
      out.push("<p>" + inlineMd(line) + "</p>");
    }
    closeLists();
    return out.join("\n");
  }

  var nav = document.getElementById("nav");
  var content = document.getElementById("content");

  function setSearchBlob(domEl, text) {
    domEl.manualSearchBlob = String(text).toLowerCase();
  }

  data.docs.forEach(function (doc) {
    var id = "doc-" + doc.slug;
    var a = document.createElement("a");
    a.href = "#" + id;
    a.className = "nav-pill";
    a.innerHTML =
      '<span class="nav-pill-icon" aria-hidden="true"></span><span class="nav-pill-label">' +
      escapeHtml(doc.title) +
      "</span>";
    setSearchBlob(a, doc.title + "\n" + doc.markdown);

    nav.appendChild(a);

    var section = document.createElement("section");
    section.className = "doc-card";
    section.id = id;
    setSearchBlob(section, doc.markdown + "\n" + doc.title);

    var head = document.createElement("button");
    head.type = "button";
    head.className = "doc-card-toggle";
    head.setAttribute("aria-expanded", "true");
    head.innerHTML =
      '<span class="doc-card-title">' +
      escapeHtml(doc.title) +
      '</span><span class="doc-card-chevron" aria-hidden="true"></span>';

    head.addEventListener("click", function (e) {
      if (e.target && e.target.closest && e.target.closest("a")) return;
      var collapsed = section.classList.toggle("collapsed");
      head.setAttribute("aria-expanded", collapsed ? "false" : "true");
    });

    var body = document.createElement("div");
    body.className = "doc-card-body";
    var inner = document.createElement("div");
    inner.className = "md-inner";
    inner.innerHTML = mdToHtml(doc.markdown);
    body.appendChild(inner);

    section.appendChild(head);
    section.appendChild(body);
    content.appendChild(section);
  });

  document.querySelectorAll(".doc-card .md-inner").forEach(function (mb) {
    wireCodeCopy(mb);
  });

  var jump = document.getElementById("jump-section");
  function syncJumpFromHash() {
    if (!jump) return;
    var h = location.hash || "";
    if (!h) {
      jump.selectedIndex = 0;
      return;
    }
    var i;
    var found = false;
    for (i = 0; i < jump.options.length; i++) {
      if (jump.options[i].value === h) {
        found = true;
        break;
      }
    }
    jump.value = found ? h : "";
  }
  if (jump) {
    data.docs.forEach(function (doc) {
      var opt = document.createElement("option");
      opt.value = "#doc-" + doc.slug;
      opt.textContent = doc.title;
      jump.appendChild(opt);
    });
    jump.addEventListener("change", function () {
      if (jump.value) location.hash = jump.value;
    });
    syncJumpFromHash();
  }

  function wireCodeCopy(root) {
    if (!root) return;
    root.querySelectorAll(".code-block-wrap").forEach(function (wrap) {
      if (wrap.querySelector(".code-copy-btn")) return;
      var pre = wrap.querySelector("pre");
      if (!pre) return;
      wrap.classList.add("has-copy");
      var btn = document.createElement("button");
      btn.type = "button";
      btn.className = "code-copy-btn";
      btn.setAttribute("aria-label", "Copy code");
      btn.textContent = "Copy";
      btn.addEventListener("click", function () {
        var code = pre.querySelector("code");
        var t = code ? code.textContent : pre.textContent;
        if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard.writeText(t).then(function () {
            btn.textContent = "Copied";
            setTimeout(function () {
              btn.textContent = "Copy";
            }, 2000);
          });
        }
      });
      wrap.appendChild(btn);
    });
  }

  function setActiveNav() {
    var hash = (location.hash || "").slice(1);
    document.querySelectorAll("a.nav-pill[href^='#']").forEach(function (a) {
      a.classList.toggle("active", a.getAttribute("href") === "#" + hash);
    });
  }
  window.addEventListener("hashchange", function () {
    setActiveNav();
    syncJumpFromHash();
  });

  var q = document.getElementById("q");
  var qSpot = document.getElementById("q-spotlight");
  var spotlight = document.getElementById("spotlight");

  function syncSearchInputs(from, to) {
    if (from && to) to.value = from.value;
  }

  function openSpotlight() {
    if (!spotlight || !qSpot) return;
    spotlight.hidden = false;
    spotlight.setAttribute("aria-hidden", "false");
    document.body.classList.add("spotlight-open");
    qSpot.value = q ? q.value : "";
    setTimeout(function () {
      qSpot.focus();
      qSpot.select();
    }, prefersReducedMotion ? 0 : 80);
  }

  function closeSpotlight() {
    if (!spotlight) return;
    spotlight.hidden = true;
    spotlight.setAttribute("aria-hidden", "true");
    document.body.classList.remove("spotlight-open");
    if (q && qSpot) {
      q.value = qSpot.value;
      filter();
    }
  }

  if (spotlight) {
    spotlight.addEventListener("click", function (e) {
      if (e.target === spotlight) closeSpotlight();
    });
    var sb = document.getElementById("spotlight-close");
    if (sb) sb.addEventListener("click", closeSpotlight);
  }

  document.addEventListener("keydown", function (e) {
    if ((e.metaKey || e.ctrlKey) && e.key === "k") {
      e.preventDefault();
      if (spotlight && spotlight.hidden) openSpotlight();
      else closeSpotlight();
    }
    if (e.key === "Escape" && spotlight && !spotlight.hidden) {
      e.preventDefault();
      closeSpotlight();
    }
  });

  var openSearchBtn = document.getElementById("open-search");
  if (openSearchBtn) openSearchBtn.addEventListener("click", openSpotlight);

  function shouldSkipHighlightEl(node) {
    var p = node.parentNode;
    if (!p || p.nodeType !== 1) return false;
    var n = p.nodeName;
    if (n === "CODE" || n === "PRE" || n === "SCRIPT" || n === "STYLE" || n === "TEXTAREA")
      return true;
    var cur = p;
    while (cur && cur.nodeType === 1) {
      if (cur.className && String(cur.className).indexOf("manual-hit") >= 0) return true;
      cur = cur.parentNode;
    }
    return false;
  }

  function stripMarks(root) {
    if (!root) return;
    root.querySelectorAll("mark.manual-hit").forEach(function (m) {
      var p = m.parentNode;
      if (!p) return;
      var t = document.createTextNode(m.textContent);
      p.replaceChild(t, m);
      p.normalize();
    });
  }

  function highlightIn(root, term) {
    if (!term || term.length < 1 || !root) return;

    var tw = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
      acceptNode: function (node) {
        if (!node.parentNode) return NodeFilter.FILTER_REJECT;
        if (shouldSkipHighlightEl(node)) return NodeFilter.FILTER_REJECT;
        var v = node.nodeValue;
        if (!v || v.length < term.length) return NodeFilter.FILTER_REJECT;
        if (v.toLowerCase().indexOf(term) < 0) return NodeFilter.FILTER_REJECT;
        return NodeFilter.FILTER_ACCEPT;
      },
    });

    var nodes = [];
    var n;
    while ((n = tw.nextNode())) nodes.push(n);

    nodes.forEach(function (textNode) {
      var text = textNode.nodeValue;
      var low = text.toLowerCase();
      var idx;
      var pos = 0;
      var frag = document.createDocumentFragment();
      while ((idx = low.indexOf(term, pos)) >= 0) {
        frag.appendChild(document.createTextNode(text.slice(pos, idx)));
        var mk = document.createElement("mark");
        mk.className = "manual-hit";
        mk.textContent = text.slice(idx, idx + term.length);
        frag.appendChild(mk);
        pos = idx + term.length;
      }
      frag.appendChild(document.createTextNode(text.slice(pos)));
      textNode.parentNode.replaceChild(frag, textNode);
    });
  }

  function blobMatchesSearchTokens(blob, term) {
    if (!term) return true;
    var parts = term.split(/\s+/).filter(function (x) {
      return x.length > 0;
    });
    if (!parts.length) return true;
    for (var i = 0; i < parts.length; i++) {
      if (blob.indexOf(parts[i]) < 0) return false;
    }
    return true;
  }

  function sectionMatches(sec, term) {
    var blob = sec.manualSearchBlob || "";
    return blobMatchesSearchTokens(blob, term);
  }

  function linkMatches(a, term) {
    var blob = a.manualSearchBlob || "";
    return blobMatchesSearchTokens(blob, term);
  }

  var emptyState = document.getElementById("search-empty");

  function syncSearchPair(e) {
    if (!q) return;
    if (!qSpot) return;
    if (e && e.target === q) qSpot.value = q.value;
    else if (e && e.target === qSpot) q.value = qSpot.value;
  }

  function filter() {
    var raw = (q && q.value) || "";
    var term = raw.trim().toLowerCase();

    nav.querySelectorAll("a.nav-pill").forEach(function (a) {
      var show = !term || linkMatches(a, term);
      a.classList.toggle("hidden", !show);
    });

    var matchCount = 0;
    document.querySelectorAll(".doc-card").forEach(function (sec) {
      var match = !term || sectionMatches(sec, term);
      sec.style.display = match ? "" : "none";
      if (match) matchCount++;
      if (match && term) sec.classList.remove("collapsed");
      var mb = sec.querySelector(".md-inner");
      stripMarks(mb);
      if (term && match) {
        var parts = term.split(/\s+/).filter(function (x) {
          return x.length > 0;
        });
        var toks = parts.length ? parts : [term];
        for (var ti = 0; ti < toks.length; ti++) {
          if (toks[ti].length >= 1) highlightIn(mb, toks[ti]);
        }
      }
    });

    var status = document.getElementById("search-status");
    if (status) {
      if (!term) status.textContent = "";
      else
        status.textContent =
          matchCount > 0
            ? matchCount + (matchCount === 1 ? " page" : " pages") + " match"
            : "No matches";
    }

    if (emptyState) {
      emptyState.hidden = !term || matchCount > 0;
    }
  }

  function onSearchInput(e) {
    syncSearchPair(e);
    filter();
  }

  if (q) {
    q.addEventListener("input", onSearchInput);
    q.addEventListener("search", onSearchInput);
  }
  if (qSpot) {
    qSpot.addEventListener("input", onSearchInput);
    qSpot.addEventListener("search", onSearchInput);
  }

  var header = document.getElementById("app-header");
  if (header && !prefersReducedMotion) {
    var onScroll = function () {
      var y =
        window.scrollY ||
        document.documentElement.scrollTop ||
        document.body.scrollTop ||
        0;
      header.classList.toggle("is-scrolled", y > 12);
    };
    window.addEventListener("scroll", onScroll, { passive: true });
    onScroll();
  }

  setActiveNav();
  if (location.hash) {
    var id = location.hash.slice(1);
    var target = document.getElementById(id);
    if (target && !prefersReducedMotion) {
      setTimeout(function () {
        target.scrollIntoView({ behavior: "smooth", block: "start" });
      }, 100);
    }
  }

  document.querySelectorAll('a[href^="#"]').forEach(function (a) {
    a.addEventListener("click", function () {
      if (prefersReducedMotion) return;
      var hid = a.getAttribute("href").slice(1);
      var t = document.getElementById(hid);
      if (t)
        setTimeout(function () {
          t.scrollIntoView({ behavior: "smooth", block: "start" });
        }, 0);
    });
  });
})();
