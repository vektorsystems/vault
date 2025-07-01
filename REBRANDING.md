# 🎨 Automatic Rebranding for Open WebUI

## Minimalist System with Environment Variables

This system performs automatic rebranding during build time using shell environment variables.

### System Files

1. **`vite-plugins/brand-replacer.ts`** - Vite plugin that replaces text during build process
2. **`vite.config.ts`** - Vite configuration with the plugin included

### Required Environment Variables

The system reads these variables from the shell environment:

```bash
export WEBUI_NAME="Your AI Brand"
export WEBUI_DESCRIPTION="Your AI interface description"
export WEBUI_COMMUNITY="Your AI Community"
```

### How It Works

1. **During build**, the plugin reads environment variables
2. **If `WEBUI_NAME` differs from "Open WebUI"**, activates rebranding
3. **Automatically replaces** all relevant text:
   - "Open WebUI" → Value of `WEBUI_NAME`
   - "Open WebUI Community" → Value of `WEBUI_COMMUNITY`
   - Descriptions in HTML and metadata

### Usage

```bash
# 1. Configure variables (with your external script)
export WEBUI_NAME="My Brand"

# 2. Normal build
npm run build
```

### Benefits

- ✅ **0 source files modified**
- ✅ **100% compatible with upstream updates**
- ✅ **No merge conflicts ever**
- ✅ **Complete control from environment variables**
- ✅ **Fully automatic build process**

### Files Processed Automatically

The plugin processes during build:
- TypeScript/JavaScript files
- Svelte components  
- JSON files
- Generated HTML
- Metadata and titles

Everything is handled automatically without modifying the original source code.

---

**✨ Result**: Fully rebranded fork that remains 100% mergeable with upstream. 