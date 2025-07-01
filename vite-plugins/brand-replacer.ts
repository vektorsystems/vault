import type { Plugin } from 'vite';

interface BrandConfig {
  name: string;
  description: string;
  community: string;
}

function getBrandConfig(): BrandConfig {
  return {
    name: process.env.WEBUI_NAME || 'Vault AI',
    description: process.env.WEBUI_DESCRIPTION || 'Vault AI is private, extensible, user-friendly interface for AI.',
    community: process.env.WEBUI_COMMUNITY || 'Vault AI Community'
  };
}

export function brandReplacer(): Plugin {
  const brandConfig = getBrandConfig();

  return {
    name: 'brand-replacer',
    transform(code: string, id: string) {
      // Skip node_modules and non-text files
      if (id.includes('node_modules') || 
          !(id.endsWith('.ts') || id.endsWith('.js') || id.endsWith('.svelte') || id.endsWith('.json'))) {
        return null;
      }
      
      let transformedCode = code;
      let hasChanges = false;
      
      // Replace brand references using word boundaries for precision
      const replacements = [
        {
          search: /\b(Open WebUI Community)\b/g,
          replace: brandConfig.community
        },
        {
          search: /\b(OpenWebUI Community)\b/g,
          replace: brandConfig.community
        },
        {
          search: /\b(WebUI)\b/g,
          replace: brandConfig.name
        },
        {
          search: /\b(Open WebUI)\b/g,
          replace: brandConfig.name
        },
        {
          search: /\b(OpenWebUI)\b/g,
          replace: brandConfig.name
        }
      ];
      
      // Apply replacements
      replacements.forEach(({ search, replace }) => {
        if (transformedCode.match(search)) {
          transformedCode = transformedCode.replace(search, replace);
          hasChanges = true;
        }
      });
      
      // Special case for API description
      if (id.includes('main.py')) {
        const descSearch = /"description": "Open WebUI is an open, extensible, user-friendly interface for AI that adapts to your workflow\."/;
        if (transformedCode.match(descSearch)) {
          transformedCode = transformedCode.replace(descSearch, `"description": "${brandConfig.description}"`);
          hasChanges = true;
        }
      }
      
      return hasChanges ? transformedCode : null;
    },
    
    generateBundle(options, bundle) {
      // Process generated files (like HTML)
      Object.keys(bundle).forEach(fileName => {
        const file = bundle[fileName];
        
        if (file.type === 'asset' && typeof file.source === 'string') {
          let content = file.source;
          let hasChanges = false;
          
          // Replace in HTML files
          if (fileName.endsWith('.html')) {
            const htmlReplacements = [
              {
                search: /<meta name="apple-mobile-web-app-title" content="[^"]*" \/>/,
                replace: `<meta name="apple-mobile-web-app-title" content="${brandConfig.name}" />`
              },
              {
                search: /<meta name="description" content="[^"]*" \/>/,
                replace: `<meta name="description" content="${brandConfig.description}" />`
              },
              {
                search: /title="[^"]*"/,
                replace: `title="${brandConfig.name}"`
              }
            ];
            
            htmlReplacements.forEach(({ search, replace }) => {
              if (content.match(search)) {
                content = content.replace(search, replace);
                hasChanges = true;
              }
            });
          }
          
          if (hasChanges) {
            file.source = content;
          }
        }
      });
    }
  };
} 