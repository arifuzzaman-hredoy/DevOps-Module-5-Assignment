import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import * as client from '../api/client'
import ProductListPage from './ProductListPage'
import type { Product } from '../types'

vi.mock('../api/client', () => ({
  getProducts: vi.fn(),
}))

const mockedGetProducts = vi.mocked(client.getProducts)

const sampleProducts: Product[] = [
  {
    id: 1,
    name: 'Classic Tee',
    description: 'A soft cotton tee.',
    price: 24.5,
    imageUrl: '/images/tee.png',
    stock: 12,
    category: 'Apparel',
    createdAt: '2024-05-01T10:00:00.000Z',
  },
  {
    id: 2,
    name: 'Trail Bottle',
    description: 'Keeps drinks cold for 24 hours.',
    price: 32,
    imageUrl: '/images/bottle.png',
    stock: 5,
    category: 'Outdoor',
    createdAt: '2024-06-12T08:30:00.000Z',
  },
]

function renderPage() {
  return render(
    <MemoryRouter>
      <ProductListPage />
    </MemoryRouter>,
  )
}

describe('ProductListPage', () => {
  beforeEach(() => {
    mockedGetProducts.mockReset()
  })

  it('shows a loading state and then renders the products', async () => {
    let resolveProducts: (products: Product[]) => void = () => {}
    mockedGetProducts.mockReturnValue(
      new Promise<Product[]>((resolve) => {
        resolveProducts = resolve
      }),
    )

    renderPage()

    expect(screen.getByText('Loading products...')).toBeInTheDocument()

    resolveProducts(sampleProducts)

    expect(await screen.findByText('Classic Tee')).toBeInTheDocument()
    expect(screen.getByText('Trail Bottle')).toBeInTheDocument()
    expect(screen.getByText('$24.50')).toBeInTheDocument()
    expect(screen.getByText('$32.00')).toBeInTheDocument()
    expect(screen.getByText('2 items')).toBeInTheDocument()
  })

  it('links each product card to its detail page', async () => {
    mockedGetProducts.mockResolvedValue(sampleProducts)

    renderPage()

    await screen.findByText('Classic Tee')

    const detailLinks = screen.getAllByRole('link', { name: /view details/i })
    expect(detailLinks).toHaveLength(sampleProducts.length)
    expect(detailLinks[0]).toHaveAttribute('href', '/products/1')
    expect(detailLinks[1]).toHaveAttribute('href', '/products/2')
  })

  it('shows an error state with a retry button when the request fails', async () => {
    const user = userEvent.setup()
    mockedGetProducts.mockRejectedValue(new Error('Request failed with status 500'))

    renderPage()

    const alert = await screen.findByRole('alert')
    expect(alert).toHaveTextContent('Unable to load products')
    expect(alert).toHaveTextContent('Request failed with status 500')

    mockedGetProducts.mockResolvedValue(sampleProducts)
    await user.click(screen.getByRole('button', { name: /retry/i }))

    expect(await screen.findByText('Classic Tee')).toBeInTheDocument()
  })
})