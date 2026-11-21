import { Link, Outlet } from 'react-router-dom'

export default function Layout() {
  return (
    <div className="app">
      <header className="site-header">
        <div className="container site-header__inner">
          <Link to="/" className="brand">
            ShopNest
          </Link>
          <nav className="site-nav" aria-label="Main navigation">
            <Link to="/" className="site-nav__link">
              Products
            </Link>
          </nav>
        </div>
      </header>

      <main className="container main">
        <Outlet />
      </main>

      <footer className="site-footer">
        <div className="container site-footer__inner">
          <span>ShopNest demo storefront</span>
          <span>Built with React + Vite</span>
        </div>
      </footer>
    </div>
  )
}