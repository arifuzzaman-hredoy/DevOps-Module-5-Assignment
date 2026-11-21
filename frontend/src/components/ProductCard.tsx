import { Link } from 'react-router-dom'
import { formatPrice } from '../lib/format'
import type { Product } from '../types'

interface ProductCardProps {
  product: Product
}

export default function ProductCard({ product }: ProductCardProps) {
  const detailPath = `/products/${product.id}`
  const inStock = product.stock > 0

  return (
    <article className="card">
      <Link to={detailPath} className="card__media" aria-label={`View ${product.name} details`}>
        <img src={product.imageUrl} alt={product.name} loading="lazy" />
      </Link>

      <div className="card__body">
        <span className="badge">{product.category}</span>
        <h2 className="card__title">
          <Link to={detailPath}>{product.name}</Link>
        </h2>
        <p className="card__price">{formatPrice(product.price)}</p>
        <div className="card__footer">
          <span className={inStock ? 'stock stock--in' : 'stock stock--out'}>
            {inStock ? `${product.stock} in stock` : 'Out of stock'}
          </span>
          <Link to={detailPath} className="card__link">
            View details
          </Link>
        </div>
      </div>
    </article>
  )
}