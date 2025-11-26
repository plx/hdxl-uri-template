import Testing
import Foundation
@testable import HDXLURITemplate

extension Tag {
  @Tag
  static var humanReadable: Self
}

// MARK: - REST API Endpoints

@Suite(.tags(.humanReadable))
struct RESTAPIEndpointTests {

  @Test
  func `basic REST API resource endpoint`() throws {
    let template = try URITemplate(parsing: "https://api.example.com/{version}/users/{userId}")

    // Simple case
    #expect(
      try template.evaluateAsString(parameters: [
        "version": "v1",
        "userId": "123"
      ]) == "https://api.example.com/v1/users/123"
    )

    // With alphanumeric user ID
    #expect(
      try template.evaluateAsString(parameters: [
        "version": "v2",
        "userId": "user_abc_456"
      ]) == "https://api.example.com/v2/users/user_abc_456"
    )

    // With UUID-style user ID
    #expect(
      try template.evaluateAsString(parameters: [
        "version": "v1",
        "userId": "550e8400-e29b-41d4-a716-446655440000"
      ]) == "https://api.example.com/v1/users/550e8400-e29b-41d4-a716-446655440000"
    )
  }

  @Test
  func `REST API with query parameters`() throws {
    let template = try URITemplate(parsing: "https://api.example.com/users{?limit,offset,sort}")

    // Single parameter
    #expect(
      try template.evaluateAsString(parameters: [
        "limit": "10"
      ]) == "https://api.example.com/users?limit=10"
    )

    // All parameters
    #expect(
      try template.evaluateAsString(parameters: [
        "limit": "25",
        "offset": "100",
        "sort": "created_at"
      ]) == "https://api.example.com/users?limit=25&offset=100&sort=created_at"
    )

    // Missing optional parameter
    #expect(
      try template.evaluateAsString(parameters: [
        "limit": "50",
        "sort": "name"
      ]) == "https://api.example.com/users?limit=50&sort=name"
    )
  }

  @Test
  func `REST API with exploded query parameters`() throws {
    let template = try URITemplate(parsing: "https://api.example.com/search{?filters*}")

    // Single filter
    #expect(
      try template.evaluateAsString(parameters: [
        "filters": .association([("status", "active")])
      ]) == "https://api.example.com/search?status=active"
    )

    // Multiple filters
    #expect(
      try template.evaluateAsString(parameters: [
        "filters": .association([
          ("status", "active"),
          ("role", "admin"),
          ("verified", "true")
        ])
      ]) == "https://api.example.com/search?status=active&role=admin&verified=true"
    )

  }

  @Test
  func `REST API nested resource`() throws {
    let template = try URITemplate(parsing: "https://api.example.com/orgs/{orgId}/teams/{teamId}/members/{memberId}")

    #expect(
      try template.evaluateAsString(parameters: [
        "orgId": "acme-corp",
        "teamId": "engineering",
        "memberId": "jsmith"
      ]) == "https://api.example.com/orgs/acme-corp/teams/engineering/members/jsmith"
    )
  }

  @Test
  func `REST API with reserved characters in path`() throws {
    let template = try URITemplate(parsing: "https://api.example.com/files/{+path}")

    // Path with slashes (reserved expansion preserves slashes)
    #expect(
      try template.evaluateAsString(parameters: [
        "path": "documents/reports/2024/q1.pdf"
      ]) == "https://api.example.com/files/documents/reports/2024/q1.pdf"
    )
  }

  @Test
  func `REST API with special characters requiring encoding`() throws {
    let template = try URITemplate(parsing: "https://api.example.com/users/{userId}/notes")

    // User ID with spaces (should be percent-encoded)
    #expect(
      try template.evaluateAsString(parameters: [
        "userId": "john doe"
      ]) == "https://api.example.com/users/john%20doe/notes"
    )

    // User ID with ampersand
    #expect(
      try template.evaluateAsString(parameters: [
        "userId": "smith&jones"
      ]) == "https://api.example.com/users/smith%26jones/notes"
    )
  }

}

// MARK: - File Download URLs

@Suite(.tags(.humanReadable))
struct FileDownloadURLTests {

  @Test
  func `CDN file download with version`() throws {
    let template = try URITemplate(parsing: "https://cdn.example.com/{bucket}/{+filepath}{?v}")

    // Simple file
    #expect(
      try template.evaluateAsString(parameters: [
        "bucket": "assets",
        "filepath": "images/logo.png",
        "v": "1.2.3"
      ]) == "https://cdn.example.com/assets/images/logo.png?v=1.2.3"
    )

    // Nested path with version
    #expect(
      try template.evaluateAsString(parameters: [
        "bucket": "static",
        "filepath": "js/vendor/react/18.2.0/react.min.js",
        "v": "abc123"
      ]) == "https://cdn.example.com/static/js/vendor/react/18.2.0/react.min.js?v=abc123"
    )
  }

  @Test
  func `download with filename and format`() throws {
    let template = try URITemplate(parsing: "https://downloads.example.com/export/{reportId}{.format}")

    #expect(
      try template.evaluateAsString(parameters: [
        "reportId": "annual-2024",
        "format": "pdf"
      ]) == "https://downloads.example.com/export/annual-2024.pdf"
    )

    #expect(
      try template.evaluateAsString(parameters: [
        "reportId": "quarterly-q1",
        "format": "xlsx"
      ]) == "https://downloads.example.com/export/quarterly-q1.xlsx"
    )

    // Without format (optional)
    #expect(
      try template.evaluateAsString(parameters: [
        "reportId": "summary"
      ]) == "https://downloads.example.com/export/summary"
    )
  }

  @Test
  func `S3-style presigned URL components`() throws {
    // Note: RFC 6570 variable names don't allow hyphens, so we use underscores
    // and use exploded association to generate the actual AWS parameter names
    let template = try URITemplate(
      parsing: "https://{bucket}.s3.{region}.amazonaws.com/{+key}{?aws_params*}"
    )

    #expect(
      try template.evaluateAsString(parameters: [
        "bucket": "my-bucket",
        "region": "us-east-1",
        "key": "uploads/2024/photo.jpg",
        "aws_params": .association([
          ("X-Amz-Algorithm", "AWS4-HMAC-SHA256"),
          ("X-Amz-Credential", "AKIAIOSFODNN7EXAMPLE"),
          ("X-Amz-Date", "20240115T120000Z"),
          ("X-Amz-Expires", "3600"),
          ("X-Amz-Signature", "abc123signature")
        ])
      ]) == "https://my-bucket.s3.us-east-1.amazonaws.com/uploads/2024/photo.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIOSFODNN7EXAMPLE&X-Amz-Date=20240115T120000Z&X-Amz-Expires=3600&X-Amz-Signature=abc123signature"
    )
  }

}

// MARK: - Search and Query URLs

@Suite(.tags(.humanReadable))
struct SearchQueryURLTests {

  @Test
  func `basic search query`() throws {
    let template = try URITemplate(parsing: "https://search.example.com/query{?q,page,per_page}")

    // Simple search
    #expect(
      try template.evaluateAsString(parameters: [
        "q": "swift programming"
      ]) == "https://search.example.com/query?q=swift%20programming"
    )

    // Search with pagination
    #expect(
      try template.evaluateAsString(parameters: [
        "q": "uri templates",
        "page": "2",
        "per_page": "20"
      ]) == "https://search.example.com/query?q=uri%20templates&page=2&per_page=20"
    )
  }

  @Test
  func `search with special characters`() throws {
    let template = try URITemplate(parsing: "https://search.example.com{?q}")

    // Query with quotes
    #expect(
      try template.evaluateAsString(parameters: [
        "q": "\"exact phrase\""
      ]) == "https://search.example.com?q=%22exact%20phrase%22"
    )

    // Query with plus sign
    #expect(
      try template.evaluateAsString(parameters: [
        "q": "C++ programming"
      ]) == "https://search.example.com?q=C%2B%2B%20programming"
    )

    // Query with hash/pound
    #expect(
      try template.evaluateAsString(parameters: [
        "q": "#hashtag"
      ]) == "https://search.example.com?q=%23hashtag"
    )
  }

  @Test
  func `faceted search with multiple values`() throws {
    let template = try URITemplate(parsing: "https://shop.example.com/products{?category,tags}")

    // Tags as comma-separated list
    #expect(
      try template.evaluateAsString(parameters: [
        "category": "electronics",
        "tags": .list(["sale", "featured", "new"])
      ]) == "https://shop.example.com/products?category=electronics&tags=sale,featured,new"
    )
  }

  @Test
  func `advanced search with exploded filters`() throws {
    let template = try URITemplate(parsing: "https://api.example.com/search{?query,filters*}")

    #expect(
      try template.evaluateAsString(parameters: [
        "query": "laptop",
        "filters": .association([
          ("price_min", "500"),
          ("price_max", "1500"),
          ("brand", "apple"),
          ("in_stock", "true")
        ])
      ]) == "https://api.example.com/search?query=laptop&price_min=500&price_max=1500&brand=apple&in_stock=true"
    )
  }

}

// MARK: - OAuth and Authentication URLs

@Suite(.tags(.humanReadable))
struct OAuthAuthenticationURLTests {

  @Test
  func `OAuth authorization URL`() throws {
    let template = try URITemplate(
      parsing: "https://auth.example.com/oauth/authorize{?client_id,redirect_uri,response_type,scope,state}"
    )

    #expect(
      try template.evaluateAsString(parameters: [
        "client_id": "my-app-123",
        "redirect_uri": "https://myapp.com/callback",
        "response_type": "code",
        "scope": "read write",
        "state": "xyz789"
      ]) == "https://auth.example.com/oauth/authorize?client_id=my-app-123&redirect_uri=https%3A%2F%2Fmyapp.com%2Fcallback&response_type=code&scope=read%20write&state=xyz789"
    )
  }

  @Test
  func `OAuth token endpoint`() throws {
    let template = try URITemplate(parsing: "https://auth.example.com/oauth/token{?grant_type,code,redirect_uri}")

    #expect(
      try template.evaluateAsString(parameters: [
        "grant_type": "authorization_code",
        "code": "auth_code_abc123",
        "redirect_uri": "https://myapp.com/callback"
      ]) == "https://auth.example.com/oauth/token?grant_type=authorization_code&code=auth_code_abc123&redirect_uri=https%3A%2F%2Fmyapp.com%2Fcallback"
    )
  }

  @Test
  func `password reset URL with token`() throws {
    let template = try URITemplate(parsing: "https://example.com/reset-password{?token,email}")

    #expect(
      try template.evaluateAsString(parameters: [
        "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9",
        "email": "user@example.com"
      ]) == "https://example.com/reset-password?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9&email=user%40example.com"
    )
  }

  @Test
  func `magic link authentication`() throws {
    let template = try URITemplate(parsing: "https://app.example.com/auth/magic{?token,expires,signature}")

    #expect(
      try template.evaluateAsString(parameters: [
        "token": "ml_abc123def456",
        "expires": "1705334400",
        "signature": "sha256_hmac_signature"
      ]) == "https://app.example.com/auth/magic?token=ml_abc123def456&expires=1705334400&signature=sha256_hmac_signature"
    )
  }

}

// MARK: - CDN and Asset URLs

@Suite(.tags(.humanReadable))
struct CDNAssetURLTests {

  @Test
  func `image with transformation parameters`() throws {
    let template = try URITemplate(parsing: "https://images.example.com/{imageId}{?w,h,fit,format,q}")

    // Basic resize
    #expect(
      try template.evaluateAsString(parameters: [
        "imageId": "hero-banner",
        "w": "1200",
        "h": "600"
      ]) == "https://images.example.com/hero-banner?w=1200&h=600"
    )

    // Full transformation
    #expect(
      try template.evaluateAsString(parameters: [
        "imageId": "product-photo-123",
        "w": "800",
        "h": "800",
        "fit": "cover",
        "format": "webp",
        "q": "85"
      ]) == "https://images.example.com/product-photo-123?w=800&h=800&fit=cover&format=webp&q=85"
    )
  }

  @Test
  func `video streaming manifest URL`() throws {
    let template = try URITemplate(parsing: "https://stream.example.com/{contentId}/{quality}/manifest{.format}")

    #expect(
      try template.evaluateAsString(parameters: [
        "contentId": "movie-12345",
        "quality": "1080p",
        "format": "m3u8"
      ]) == "https://stream.example.com/movie-12345/1080p/manifest.m3u8"
    )

    #expect(
      try template.evaluateAsString(parameters: [
        "contentId": "live-event-99",
        "quality": "auto",
        "format": "mpd"
      ]) == "https://stream.example.com/live-event-99/auto/manifest.mpd"
    )
  }

  @Test
  func `font file with subset parameter`() throws {
    let template = try URITemplate(parsing: "https://fonts.example.com/{family}/{weight}{.format}{?subset}")

    #expect(
      try template.evaluateAsString(parameters: [
        "family": "roboto",
        "weight": "400",
        "format": "woff2",
        "subset": "latin"
      ]) == "https://fonts.example.com/roboto/400.woff2?subset=latin"
    )
  }

}

// MARK: - Pagination URLs

@Suite(.tags(.humanReadable))
struct PaginationURLTests {

  @Test
  func `offset-based pagination`() throws {
    let template = try URITemplate(parsing: "https://api.example.com/items{?offset,limit}")

    // First page
    #expect(
      try template.evaluateAsString(parameters: [
        "offset": "0",
        "limit": "20"
      ]) == "https://api.example.com/items?offset=0&limit=20"
    )

    // Later page
    #expect(
      try template.evaluateAsString(parameters: [
        "offset": "100",
        "limit": "20"
      ]) == "https://api.example.com/items?offset=100&limit=20"
    )
  }

  @Test
  func `cursor-based pagination`() throws {
    let template = try URITemplate(parsing: "https://api.example.com/feed{?cursor,limit,direction}")

    // Initial request
    #expect(
      try template.evaluateAsString(parameters: [
        "limit": "50"
      ]) == "https://api.example.com/feed?limit=50"
    )

    // With cursor
    #expect(
      try template.evaluateAsString(parameters: [
        "cursor": "eyJpZCI6MTIzNDV9",
        "limit": "50",
        "direction": "next"
      ]) == "https://api.example.com/feed?cursor=eyJpZCI6MTIzNDV9&limit=50&direction=next"
    )
  }

  @Test
  func `page-based pagination with sorting`() throws {
    let template = try URITemplate(parsing: "https://api.example.com/posts{?page,size,sort,order}")

    #expect(
      try template.evaluateAsString(parameters: [
        "page": "3",
        "size": "25",
        "sort": "created_at",
        "order": "desc"
      ]) == "https://api.example.com/posts?page=3&size=25&sort=created_at&order=desc"
    )
  }

}

// MARK: - Webhook and Callback URLs

@Suite(.tags(.humanReadable))
struct WebhookCallbackURLTests {

  @Test
  func `webhook delivery URL`() throws {
    let template = try URITemplate(parsing: "https://{subdomain}.hooks.example.com/v1/webhooks/{webhookId}/deliver")

    #expect(
      try template.evaluateAsString(parameters: [
        "subdomain": "customer-123",
        "webhookId": "wh_abc123"
      ]) == "https://customer-123.hooks.example.com/v1/webhooks/wh_abc123/deliver"
    )
  }

  @Test
  func `payment callback URL with transaction details`() throws {
    let template = try URITemplate(
      parsing: "https://shop.example.com/checkout/callback{?transaction_id,status,amount,currency}"
    )

    #expect(
      try template.evaluateAsString(parameters: [
        "transaction_id": "txn_1234567890",
        "status": "success",
        "amount": "9999",
        "currency": "USD"
      ]) == "https://shop.example.com/checkout/callback?transaction_id=txn_1234567890&status=success&amount=9999&currency=USD"
    )
  }

  @Test
  func `event notification URL with signature`() throws {
    let template = try URITemplate(
      parsing: "https://api.example.com/events/{eventType}/notify{?timestamp,nonce,signature}"
    )

    #expect(
      try template.evaluateAsString(parameters: [
        "eventType": "order.completed",
        "timestamp": "1705334400",
        "nonce": "random123",
        "signature": "hmac_sha256_sig"
      ]) == "https://api.example.com/events/order.completed/notify?timestamp=1705334400&nonce=random123&signature=hmac_sha256_sig"
    )
  }

}

// MARK: - E-Commerce and Product URLs

@Suite(.tags(.humanReadable))
struct ECommerceProductURLTests {

  @Test
  func `product detail URL with variant`() throws {
    let template = try URITemplate(parsing: "https://shop.example.com/products/{productSlug}{?variant,color,size}")

    // Simple product
    #expect(
      try template.evaluateAsString(parameters: [
        "productSlug": "classic-t-shirt"
      ]) == "https://shop.example.com/products/classic-t-shirt"
    )

    // With variant options
    #expect(
      try template.evaluateAsString(parameters: [
        "productSlug": "classic-t-shirt",
        "variant": "v123",
        "color": "navy-blue",
        "size": "XL"
      ]) == "https://shop.example.com/products/classic-t-shirt?variant=v123&color=navy-blue&size=XL"
    )
  }

  @Test
  func `category browsing with filters`() throws {
    let template = try URITemplate(
      parsing: "https://shop.example.com/categories/{category}{/subcategory}{?brand,price_range,sort}"
    )

    // Top-level category
    #expect(
      try template.evaluateAsString(parameters: [
        "category": "electronics"
      ]) == "https://shop.example.com/categories/electronics"
    )

    // With subcategory
    #expect(
      try template.evaluateAsString(parameters: [
        "category": "electronics",
        "subcategory": "laptops"
      ]) == "https://shop.example.com/categories/electronics/laptops"
    )

    // With filters
    #expect(
      try template.evaluateAsString(parameters: [
        "category": "electronics",
        "subcategory": "laptops",
        "brand": "apple",
        "price_range": "1000-2000",
        "sort": "price-asc"
      ]) == "https://shop.example.com/categories/electronics/laptops?brand=apple&price_range=1000-2000&sort=price-asc"
    )
  }

  @Test
  func `cart and checkout URLs`() throws {
    let template = try URITemplate(parsing: "https://shop.example.com/cart/{cartId}/checkout{?step,promo}")

    #expect(
      try template.evaluateAsString(parameters: [
        "cartId": "cart_abc123",
        "step": "shipping",
        "promo": "SAVE20"
      ]) == "https://shop.example.com/cart/cart_abc123/checkout?step=shipping&promo=SAVE20"
    )
  }

}

// MARK: - Social Media Share URLs

@Suite(.tags(.humanReadable))
struct SocialMediaShareURLTests {

  @Test
  func `Twitter/X share intent`() throws {
    let template = try URITemplate(parsing: "https://twitter.com/intent/tweet{?text,url,hashtags,via}")

    #expect(
      try template.evaluateAsString(parameters: [
        "text": "Check out this amazing article!",
        "url": "https://blog.example.com/post/123",
        "hashtags": "tech,programming",
        "via": "exampleapp"
      ]) == "https://twitter.com/intent/tweet?text=Check%20out%20this%20amazing%20article%21&url=https%3A%2F%2Fblog.example.com%2Fpost%2F123&hashtags=tech%2Cprogramming&via=exampleapp"
    )
  }

  @Test
  func `Facebook share URL`() throws {
    let template = try URITemplate(parsing: "https://www.facebook.com/sharer/sharer.php{?u,quote}")

    #expect(
      try template.evaluateAsString(parameters: [
        "u": "https://example.com/article",
        "quote": "Great read!"
      ]) == "https://www.facebook.com/sharer/sharer.php?u=https%3A%2F%2Fexample.com%2Farticle&quote=Great%20read%21"
    )
  }

  @Test
  func `LinkedIn share URL`() throws {
    let template = try URITemplate(parsing: "https://www.linkedin.com/sharing/share-offsite/{?url}")

    #expect(
      try template.evaluateAsString(parameters: [
        "url": "https://example.com/professional-article"
      ]) == "https://www.linkedin.com/sharing/share-offsite/?url=https%3A%2F%2Fexample.com%2Fprofessional-article"
    )
  }

  @Test
  func `email share mailto link`() throws {
    let template = try URITemplate(parsing: "mailto:{?to,subject,body}")

    #expect(
      try template.evaluateAsString(parameters: [
        "to": "friend@example.com",
        "subject": "Check this out!",
        "body": "I found this interesting: https://example.com"
      ]) == "mailto:?to=friend%40example.com&subject=Check%20this%20out%21&body=I%20found%20this%20interesting%3A%20https%3A%2F%2Fexample.com"
    )
  }

}

// MARK: - Internationalization and Unicode

@Suite(.tags(.humanReadable))
struct InternationalizationUnicodeTests {

  @Test
  func `Japanese characters in path`() throws {
    let template = try URITemplate(parsing: "https://example.jp/products/{productName}")

    #expect(
      try template.evaluateAsString(parameters: [
        "productName": "寿司セット"
      ]) == "https://example.jp/products/%E5%AF%BF%E5%8F%B8%E3%82%BB%E3%83%83%E3%83%88"
    )
  }

  @Test
  func `German umlauts in query`() throws {
    let template = try URITemplate(parsing: "https://example.de/search{?q}")

    #expect(
      try template.evaluateAsString(parameters: [
        "q": "Größe"
      ]) == "https://example.de/search?q=Gr%C3%B6%C3%9Fe"
    )
  }

  @Test
  func `emoji in user content`() throws {
    let template = try URITemplate(parsing: "https://api.example.com/posts{?title,tags}")

    // Emoji in title
    #expect(
      try template.evaluateAsString(parameters: [
        "title": "Hello World! 🌍"
      ]) == "https://api.example.com/posts?title=Hello%20World%21%20%F0%9F%8C%8D"
    )

    // Multiple emoji
    #expect(
      try template.evaluateAsString(parameters: [
        "title": "🎉 Party Time! 🎊",
        "tags": "celebration,fun"
      ]) == "https://api.example.com/posts?title=%F0%9F%8E%89%20Party%20Time%21%20%F0%9F%8E%8A&tags=celebration%2Cfun"
    )
  }

  @Test
  func `Chinese characters in search`() throws {
    let template = try URITemplate(parsing: "https://example.cn/search{?keyword}")

    #expect(
      try template.evaluateAsString(parameters: [
        "keyword": "北京饭店"
      ]) == "https://example.cn/search?keyword=%E5%8C%97%E4%BA%AC%E9%A5%AD%E5%BA%97"
    )
  }

  @Test
  func `Arabic text in path`() throws {
    let template = try URITemplate(parsing: "https://example.ae/articles/{title}")

    #expect(
      try template.evaluateAsString(parameters: [
        "title": "مرحبا"
      ]) == "https://example.ae/articles/%D9%85%D8%B1%D8%AD%D8%A8%D8%A7"
    )
  }

  @Test
  func `mixed script content`() throws {
    let template = try URITemplate(parsing: "https://example.com/translate{?from,to,text}")

    #expect(
      try template.evaluateAsString(parameters: [
        "from": "en",
        "to": "ja",
        "text": "Hello こんにちは"
      ]) == "https://example.com/translate?from=en&to=ja&text=Hello%20%E3%81%93%E3%82%93%E3%81%AB%E3%81%A1%E3%81%AF"
    )
  }

  @Test
  func `emoji in hashtags`() throws {
    let template = try URITemplate(parsing: "https://social.example.com/tags/{tag}")

    #expect(
      try template.evaluateAsString(parameters: [
        "tag": "🔥hot"
      ]) == "https://social.example.com/tags/%F0%9F%94%A5hot"
    )
  }

  @Test
  func `Russian Cyrillic in query`() throws {
    let template = try URITemplate(parsing: "https://example.ru/search{?city}")

    #expect(
      try template.evaluateAsString(parameters: [
        "city": "Москва"
      ]) == "https://example.ru/search?city=%D0%9C%D0%BE%D1%81%D0%BA%D0%B2%D0%B0"
    )
  }

}

// MARK: - Fragment Identifiers

@Suite(.tags(.humanReadable))
struct FragmentIdentifierTests {

  @Test
  func `documentation anchor links`() throws {
    let template = try URITemplate(parsing: "https://docs.example.com/{section}{#anchor}")

    #expect(
      try template.evaluateAsString(parameters: [
        "section": "api-reference",
        "anchor": "authentication"
      ]) == "https://docs.example.com/api-reference#authentication"
    )

    // Without anchor
    #expect(
      try template.evaluateAsString(parameters: [
        "section": "getting-started"
      ]) == "https://docs.example.com/getting-started"
    )
  }

  @Test
  func `single page app routes`() throws {
    let template = try URITemplate(parsing: "https://app.example.com/{#route}")

    #expect(
      try template.evaluateAsString(parameters: [
        "route": "dashboard/settings"
      ]) == "https://app.example.com/#dashboard/settings"
    )

    #expect(
      try template.evaluateAsString(parameters: [
        "route": "users/123/profile"
      ]) == "https://app.example.com/#users/123/profile"
    )
  }

}
