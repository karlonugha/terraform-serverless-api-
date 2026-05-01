import { useState } from 'react'
import ShortenForm from './components/ShortenForm'
import UrlList from './components/UrlList'

const API_URL = import.meta.env.VITE_API_URL || ''

export default function App() {
  const [urls, setUrls] = useState([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  async function handleShorten(longUrl) {
    setError('')
    setLoading(true)
    try {
      const res = await fetch(`${API_URL}/shorten`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ url: longUrl }),
      })
      if (!res.ok) {
        const data = await res.json().catch(() => ({}))
        throw new Error(data.error || `HTTP ${res.status}`)
      }
      const data = await res.json()
      setUrls(prev => [data, ...prev])
    } catch (err) {
      setError(err.message || 'Failed to shorten URL')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gray-950 text-white">
      {/* Header */}
      <header className="border-b border-gray-800">
        <div className="max-w-3xl mx-auto px-6 py-8">
          <div className="flex items-center gap-3 mb-2">
            <span className="text-3xl">🔗</span>
            <h1 className="text-3xl font-bold">URL Shortener</h1>
          </div>
          <p className="text-gray-400">
            Serverless URL shortener powered by AWS Lambda, API Gateway, and DynamoDB.
          </p>
        </div>
      </header>

      {/* Main */}
      <main className="max-w-3xl mx-auto px-6 py-10">
        <ShortenForm onShorten={handleShorten} loading={loading} />

        {error && (
          <div className="mt-4 p-4 bg-red-500/10 border border-red-500/30 rounded-xl text-red-400 text-sm">
            {error}
          </div>
        )}

        {urls.length > 0 && (
          <div className="mt-10">
            <h2 className="text-lg font-semibold text-gray-300 mb-4">
              Your Shortened URLs
            </h2>
            <UrlList urls={urls} />
          </div>
        )}
      </main>

      {/* Footer */}
      <footer className="border-t border-gray-800 mt-20">
        <div className="max-w-3xl mx-auto px-6 py-6 text-center text-gray-600 text-sm">
          Built with React + Tailwind CSS · Backend: Lambda + API Gateway + DynamoDB · Deployed with Terraform
        </div>
      </footer>
    </div>
  )
}
