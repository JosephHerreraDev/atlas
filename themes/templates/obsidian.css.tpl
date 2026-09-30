/* Prometheus Theme for Obsidian */

.theme-dark, .theme-light {
  /* Core colors */
  --background-primary: {{ background }};
  --background-primary-alt: {{ surface }};
  --background-secondary: {{ surface }};
  --background-secondary-alt: {{ surface_hover }};
  --text-normal: {{ foreground }};

  /* Selection colors */
  --text-selection: {{ selection_background }};

  /* Border color */
  --background-modifier-border: {{ border }};

  /* Semantic heading colors */
  --text-title-h1: {{ ansi_red }};
  --text-title-h2: {{ ansi_green }};
  --text-title-h3: {{ ansi_yellow }};
  --text-title-h4: {{ ansi_blue }};
  --text-title-h5: {{ ansi_magenta }};
  --text-title-h6: {{ ansi_cyan }};

  /* Links and accents */
  --text-link: {{ info }};
  --text-accent: {{ accent }};
  --text-accent-hover: {{ accent }};
  --interactive-accent: {{ accent }};
  --interactive-accent-hover: {{ accent }};

  /* Muted text */
  --text-muted: {{ foreground_muted }};
  --text-faint: color-mix(in srgb, {{ foreground_muted }} 70%, transparent);

  /* Code */
  --code-normal: {{ ansi_cyan }};

  /* Errors and success */
  --text-error: {{ error }};
  --text-error-hover: {{ error }};
  --text-success: {{ success }};

  /* Tags */
  --tag-color: {{ info }};
  --tag-background: {{ surface_hover }};

  /* Graph */
  --graph-line: {{ border }};
  --graph-node: {{ accent }};
  --graph-node-focused: {{ info }};
  --graph-node-tag: {{ ansi_cyan }};
  --graph-node-attachment: {{ success }};
}

/* Headers */
.cm-header-1, .markdown-rendered h1 { color: var(--text-title-h1); }
.cm-header-2, .markdown-rendered h2 { color: var(--text-title-h2); }
.cm-header-3, .markdown-rendered h3 { color: var(--text-title-h3); }
.cm-header-4, .markdown-rendered h4 { color: var(--text-title-h4); }
.cm-header-5, .markdown-rendered h5 { color: var(--text-title-h5); }
.cm-header-6, .markdown-rendered h6 { color: var(--text-title-h6); }

/* Code blocks */
.markdown-rendered code {
  color: {{ ansi_cyan }};
}

/* Syntax highlighting */
.cm-s-obsidian span.cm-keyword { color: {{ ansi_red }}; }
.cm-s-obsidian span.cm-string { color: {{ ansi_green }}; }
.cm-s-obsidian span.cm-number { color: {{ ansi_yellow }}; }
.cm-s-obsidian span.cm-comment { color: {{ foreground_muted }}; }
.cm-s-obsidian span.cm-operator { color: {{ ansi_blue }}; }
.cm-s-obsidian span.cm-def { color: {{ ansi_blue }}; }

/* Links */
.markdown-rendered a {
  color: var(--text-link);
}

/* Blockquotes */
.markdown-rendered blockquote {
  border-left-color: {{ accent }};
}

/* Active elements */
.workspace-leaf.mod-active .workspace-leaf-header-title {
  color: var(--interactive-accent);
}

.nav-file-title.is-active {
  color: var(--interactive-accent);
}

/* Search results */
.search-result-file-title {
  color: var(--interactive-accent);
}
