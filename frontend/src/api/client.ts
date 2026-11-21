import type { Product } from '../types'

const BASE_URL = import.meta.env.VITE_API_BASE_URL ?? ''

async function request<T>(path: string): Promise<T> {
  const response = await fetch(`${BASE_URL}${path}`, {
    headers: { Accept: 'application/json' },
  })

  if (!response.ok) {
    const statusText = response.statusText ? ` ${response.statusText}` : ''
    throw new Error(`Request failed with status ${response.status}${statusText}`)
  }

  return (await response.json()) as T
}

export function getProducts(): Promise<Product[]> {
  return request<Product[]>('/api/products')
}

export function getProduct(id: number): Promise<Product> {
  return request<Product>(`/api/products/${id}`)
}