import { useState } from 'react'

export default function UrlList({ urls }) {
  return (
    <div className="space-y-3">
      {urls.map((item, i) => (
        <UrlCard key={item.code || i} item={item} />
      ))}
    </div>
  )
}

function UrlCard({ item }) {
  const [copied, setCopied] = useState(false)

  async function handleCopy() {
    try {
      await navigator.clipboard.writeText(item.shortUrl)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch {
      // Fallback for older browsers
      const input = document.createElement('input')
      input.value = item.shortUrl
      document.body.appendChild(input)
      input.select()
      document.execCommand('copy')
      document.body.removeChild(input)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    }
  }

  return (
    <div className="bg-gray-900 border border-gray-800 rounded-xl p-4 flex items-center gap-4">
      {/* Short URL */}
      <div className="flex-1 min-w-0">
        <a
          href={item.shortUrl}
          target="_blank"
          rel="noreferrer"
          className="text-sky-400 hover:text-sky-300 font-medium text-sm truncate block"
        >
          {item.shortUrl}
        </a>
        <p className="text-gray-500 text-xs mt-1 truncate" title={item.originalUrl}>
          {item.originalUrl}
        </p>
      </div>

      {/* Code badge */}
      <span className="text-xs px-2 py-1 bg-gray-800 border border-gray-700 text-gray-400 rounded-md font-mono">
        {item.code}
      </span>

      {/* Copy button */}
      <button
        onClick={handleCopy}
        className={`px-4 py-2 text-xs font-medium rounded-lg transition-colors ${
          copied
            ? 'bg-green-600/20 text-green-400 border border-green-600/30'
            : 'bg-gray-800 text-gray-300 hover:bg-gray-700 border border-gray-700'
        }`}
      >
        {copied ? '✓ Copied' : 'Copy'}
      </button>
    </div>
  )
}
