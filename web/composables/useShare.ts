/**
 * Share functionality for Relanote Playground
 * Encodes/decodes code in URL hash for sharing
 */

// Compress string using simple LZ-based compression
function compress(str: string): string {
  // Use TextEncoder to handle unicode properly
  const encoder = new TextEncoder();
  const bytes = encoder.encode(str);

  // Convert to base64
  let binary = '';
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }

  // Use URL-safe base64
  return btoa(binary)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

// Decompress string
function decompress(str: string): string {
  // Restore standard base64
  let base64 = str
    .replace(/-/g, '+')
    .replace(/_/g, '/');

  // Add padding if needed
  while (base64.length % 4) {
    base64 += '=';
  }

  try {
    const binary = atob(base64);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i++) {
      bytes[i] = binary.charCodeAt(i);
    }

    const decoder = new TextDecoder();
    return decoder.decode(bytes);
  } catch {
    return '';
  }
}

export function useShare() {
  const isShared = ref(false);
  const shareUrl = ref('');
  const showCopied = ref(false);

  // Get code from URL hash
  const getCodeFromUrl = (): string | null => {
    if (typeof window === 'undefined') return null;

    const hash = window.location.hash;
    if (!hash || !hash.startsWith('#code=')) return null;

    const encoded = hash.slice(6); // Remove '#code='
    if (!encoded) return null;

    try {
      return decompress(encoded);
    } catch {
      return null;
    }
  };

  // Create share URL from code
  const createShareUrl = (code: string): string => {
    if (typeof window === 'undefined') return '';

    const encoded = compress(code);
    const baseUrl = window.location.origin + window.location.pathname;
    return `${baseUrl}#code=${encoded}`;
  };

  // Share current code
  const share = async (code: string): Promise<boolean> => {
    const url = createShareUrl(code);
    shareUrl.value = url;

    // Update URL without reload
    window.history.replaceState(null, '', url);
    isShared.value = true;

    // Copy to clipboard
    try {
      await navigator.clipboard.writeText(url);
      showCopied.value = true;
      setTimeout(() => {
        showCopied.value = false;
      }, 2000);
      return true;
    } catch {
      // Fallback for older browsers
      const textArea = document.createElement('textarea');
      textArea.value = url;
      textArea.style.position = 'fixed';
      textArea.style.left = '-9999px';
      document.body.appendChild(textArea);
      textArea.select();
      try {
        document.execCommand('copy');
        showCopied.value = true;
        setTimeout(() => {
          showCopied.value = false;
        }, 2000);
        return true;
      } catch {
        return false;
      } finally {
        document.body.removeChild(textArea);
      }
    }
  };

  // Clear share state (when code changes)
  const clearShare = () => {
    if (isShared.value) {
      isShared.value = false;
      // Remove hash from URL
      if (typeof window !== 'undefined') {
        window.history.replaceState(null, '', window.location.pathname);
      }
    }
  };

  return {
    isShared,
    shareUrl,
    showCopied,
    getCodeFromUrl,
    createShareUrl,
    share,
    clearShare,
  };
}
