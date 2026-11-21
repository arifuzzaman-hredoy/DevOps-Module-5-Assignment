import { useCallback, useEffect, useState } from 'react'
import { getProducts } from '../api/client'
import ProductCard from '../components/ProductCard'
import type { Product } from '../types'

type Status = 'loading' | 'success' | 'error'

const SKELETON_COUNT = 6

export default function ProductListPage() {
  const [products, setProducts] = useState<Product[]>([])
  const [status, setStatus] = useState<Status>('loading')
  const [error, setError] = useState<string | null>(null)

  const load = useCallback(async () => {
    setStatus('loading')
    setError(null)

    try {
      const data = await getProducts()
      setProducts(data)
      setStatus('success')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load products')
      setStatus('error')
    }
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  return (
    <section className="page">
      <header className="page__header">
        <div>
          <h1 className="page__title">Products</h1>
          <p className="page__subtitle">Browse the ShopNest catalog.</p>
        </div>
        {status === 'success' && <span className="page__count">{products.length} items</span>}
      </header>

      {status === 'loading' && (
        <div className="state" role="status">
          <p className="state__text">Loading products...</p>
          <div className="grid" aria-hidden="true">
            {Array.from({ length: SKELETON_COUNT }, (_, index) => (
              <div key={index} className="card card--skeleton">
                <div className="skeleton skeleton--media" />
                <div className="card__body">
                  <div className="skeleton skeleton--badge" />
                  <div className="skeleton skeleton--title" />
                  <div className="skeleton skeleton--price" />
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {status === 'error' && (
        <div className="state state--error" role="alert">
          <h2 className="state__title">Unable to load products</h2>
          <p className="state__text">{error}</p>
          <button type="button" className="btn" onClick={() => void load()}>
            Retry
          </button>
        </div>
      )}

      {status === 'success' && products.length === 0 && (
        <div className="state">
          <h2 className="state__title">No products yet</h2>
          <p className="state__text">Check back later for new arrivals.</p>
        </div>
      )}

      {status === 'success' && products.length > 0 && (
        <div className="grid">
          {products.map((product) => (
            <ProductCard key={product.id} product={product} />
          ))}
        </div>
      )}
    </section>
  )
}