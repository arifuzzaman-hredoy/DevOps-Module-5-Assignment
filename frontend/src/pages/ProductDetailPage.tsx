import { useCallback, useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { getProduct } from '../api/client'
import { formatDate, formatPrice } from '../lib/format'
import type { Product } from '../types'

type Status = 'loading' | 'success' | 'error' | 'not-found'

export default function ProductDetailPage() {
  const { id } = useParams<{ id: string }>()
  const productId = Number(id)
  const isValidId = Number.isInteger(productId) && productId > 0

  const [product, setProduct] = useState<Product | null>(null)
  const [status, setStatus] = useState<Status>('loading')
  const [error, setError] = useState<string | null>(null)

  const load = useCallback(async () => {
    if (!isValidId) {
      setStatus('not-found')
      return
    }

    setStatus('loading')
    setError(null)

    try {
      const data = await getProduct(productId)
      setProduct(data)
      setStatus('success')
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to load product'
      if (message.includes('404')) {
        setStatus('not-found')
        return
      }
      setError(message)
      setStatus('error')
    }
  }, [isValidId, productId])

  useEffect(() => {
    void load()
  }, [load])

  return (
    <section className="page">
      <Link to="/" className="back-link">
        &larr; Back to products
      </Link>

      {status === 'loading' && (
        <div className="state" role="status">
          <p className="state__text">Loading product...</p>
          <div className="detail detail--skeleton" aria-hidden="true">
            <div className="skeleton skeleton--detail-media" />
            <div className="detail__info">
              <div className="skeleton skeleton--badge" />
              <div className="skeleton skeleton--title" />
              <div className="skeleton skeleton--price" />
              <div className="skeleton skeleton--line" />
              <div className="skeleton skeleton--line" />
            </div>
          </div>
        </div>
      )}

      {status === 'not-found' && (
        <div className="state state--error" role="alert">
          <h1 className="state__title">Product not found</h1>
          <p className="state__text">The product you are looking for does not exist.</p>
          <Link to="/" className="btn">
            Back to products
          </Link>
        </div>
      )}

      {status === 'error' && (
        <div className="state state--error" role="alert">
          <h1 className="state__title">Unable to load product</h1>
          <p className="state__text">{error}</p>
          <button type="button" className="btn" onClick={() => void load()}>
            Retry
          </button>
        </div>
      )}

      {status === 'success' && product && (
        <article className="detail">
          <div className="detail__media">
            <img src={product.imageUrl} alt={product.name} />
          </div>

          <div className="detail__info">
            <span className="badge">{product.category}</span>
            <h1 className="detail__title">{product.name}</h1>
            <p className="detail__price">{formatPrice(product.price)}</p>
            <p className={product.stock > 0 ? 'stock stock--in' : 'stock stock--out'}>
              {product.stock > 0 ? `${product.stock} in stock` : 'Out of stock'}
            </p>

            <p className="detail__description">{product.description}</p>

            <dl className="detail__meta">
              <div className="detail__meta-item">
                <dt>Stock</dt>
                <dd>{product.stock}</dd>
              </div>
              <div className="detail__meta-item">
                <dt>Created</dt>
                <dd>{formatDate(product.createdAt)}</dd>
              </div>
              <div className="detail__meta-item">
                <dt>Category</dt>
                <dd>{product.category}</dd>
              </div>
            </dl>

            <Link to="/" className="btn">
              Back to products
            </Link>
          </div>
        </article>
      )}
    </section>
  )
}