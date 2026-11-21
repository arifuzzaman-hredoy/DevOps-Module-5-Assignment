import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { getProduct, getProducts } from './client'
import type { Product } from '../types'

const sampleProduct: Product = {
  id: 1,
  name: 'Classic Tee',
  description: 'A soft cotton tee.',
  price: 24.5,
  imageUrl: 'https://example.com/tee.png',
  stock: 12,
  category: 'Apparel',
  createdAt: '2024-05-01T10:00:00.000Z',
}

function jsonResponse(body: unknown, init: ResponseInit = {}): Response {
  return new Response(JSON.stringify(body), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
    ...init,
  })
}

describe('api client', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('getProducts() requests /api/products and returns parsed products', async () => {
    const fetchMock = vi.fn().mockResolvedValue(jsonResponse([sampleProduct]))
    vi.stubGlobal('fetch', fetchMock)

    const products = await getProducts()

    expect(fetchMock).toHaveBeenCalledTimes(1)
    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit]
    expect(url).toBe('/api/products-wrong')
    expect(init.headers).toEqual({ Accept: 'application/json' })
    expect(products).toEqual([sampleProduct])
  })

  it('getProduct(id) requests /api/products/{id} and returns a product', async () => {
    const fetchMock = vi.fn().mockResolvedValue(jsonResponse(sampleProduct))
    vi.stubGlobal('fetch', fetchMock)

    const product = await getProduct(1)

    expect(fetchMock).toHaveBeenCalledTimes(1)
    const [url] = fetchMock.mock.calls[0] as [string, RequestInit]
    expect(url).toBe('/api/products/1')
    expect(product).toEqual(sampleProduct)
  })

  it('rejects with the status text when the response is not ok', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue(
        new Response(null, { status: 500, statusText: 'Internal Server Error' }),
      ),
    )

    await expect(getProducts()).rejects.toThrow(/500/)
    await expect(getProduct(1)).rejects.toThrow(/Internal Server Error/)
  })
})