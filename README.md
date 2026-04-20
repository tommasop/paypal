# PayPal

PayPal integration using [Tesla](https://github.com/elixir-tesla/tesla).

The aim of this library is to get completely covered the use of the PayPal API v2 for Orders, Payments, Authorization, and Webhooks.

## Features

- **Orders**: Create, authorize, capture, and manage PayPal orders
- **Payments**: Handle payment captures, refunds, and authorizations
- **Webhooks**: Receive real-time notifications about payment events
- **Authentication**: Automatic token management with lazy initialization
- **Lazy Configuration**: Config is read at request time, allowing runtime configuration

## Installation

Add `paypal` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:paypal, "~> 0.1.0"}
  ]
end
```

## Configuration

PayPal uses **lazy configuration** - credentials are read when making API calls, not at application startup. This allows you to configure PayPal at runtime.

### Method 1: Config Files (Traditional)

Configure in `config/runtime.exs` (recommended) or `config/config.exs`:

```elixir
config :paypal,
  client_id: System.fetch_env!("PAYPAL_CLIENT_ID"),
  secret: System.fetch_env!("PAYPAL_SECRET"),
  url: System.fetch_env!("PAYPAL_URL")  # "https://api.sandbox.paypal.com" or "https://api.paypal.com"
```

### Method 2: Runtime Configuration

Configure dynamically at runtime before making API calls:

```elixir
# Set configuration at runtime
Application.put_env(:paypal, :client_id, "your_client_id")
Application.put_env(:paypal, :secret, "your_secret")
Application.put_env(:paypal, :url, "https://api.sandbox.paypal.com")

# Now make API calls
{:ok, order} = Paypal.Order.create(:capture, [...])
```

### Method 3: Via Parent Library (e.g., MagicMerchant)

When used as a dependency in libraries like MagicMerchant, the parent library can set configuration before starting PayPal operations:

```elixir
# Parent library configures PayPal from its own config
config = %{
  url: "https://api.sandbox.paypal.com",
  client_id: "client_id",
  secret: "secret"
}

Application.put_env(:paypal, :url, config.url)
Application.put_env(:paypal, :client_id, config.client_id)
Application.put_env(:paypal, :secret, config.secret)
```

### Configuration Options

| Option | Required | Description |
|--------|----------|-------------|
| `:client_id` | Yes | PayPal REST API Client ID |
| `:secret` | Yes | PayPal REST API Secret |
| `:url` | Yes | PayPal API URL (sandbox or production) |
| `:auto_refresh` | No | Auto-refresh OAuth token (default: `true`) |

## Usage

### Orders

```elixir
# Create an order for capture
{:ok, order} = Paypal.Order.create(:capture, [
  %{"amount" => %{"currency_code" => "USD", "value" => "10.00"}}
], %{
  "return_url" => "https://example.com/success",
  "cancel_url" => "https://example.com/cancel"
})

# Authorize an order
{:ok, authorized} = Paypal.Order.authorize(order.id)

# Capture an order
{:ok, captured} = Paypal.Order.capture(order.id)
```

### Payments

```elixir
# Capture an authorization
{:ok, payment} = Paypal.Payment.capture("AUTHORIZATION_ID")

# Refund a payment
{:ok, refund} = Paypal.Payment.refund("CAPTURE_ID")

# Show payment details
{:ok, info} = Paypal.Payment.show("PAYMENT_ID")
```

### Webhooks

Webhooks allow your application to receive real-time notifications when events happen with your PayPal transactions.

#### Creating a Webhook

```elixir
{:ok, webhook} = Paypal.Webhook.create(%{
  url: "https://myapp.com/webhooks/paypal",
  event_types: ["PAYMENT.CAPTURE.COMPLETED", "CHECKOUT.ORDER.APPROVED"]
})
```

#### Listing Webhooks

```elixir
{:ok, webhooks} = Paypal.Webhook.list()
```

#### Verifying Webhook Signatures

For security, always verify webhook signatures to ensure they're authentic:

```elixir
# In your Phoenix controller
def handle_webhook(conn, params) do
  headers = Enum.into(conn.req_headers, %{})

  case Paypal.Webhook.verify_signature(params, headers) do
    {:ok, :verified} ->
      # Process the webhook
      handle_event(params)
      send_resp(conn, 200, "OK")

    {:error, reason} ->
      send_resp(conn, 400, "Invalid signature")
  end
end
```

#### Parsing Webhook Events

```elixir
{:ok, event} = Paypal.Webhook.parse_event(params)

# Check event type
if Paypal.Webhook.Event.payment_event?(event) do
  # Handle payment event
end

if Paypal.Webhook.Event.order_event?(event) do
  # Handle order event
end
```

#### Available Event Types

The library supports all PayPal webhook event types:

- **Payment Events**: `PAYMENT.CAPTURE.COMPLETED`, `PAYMENT.CAPTURE.DENIED`, etc.
- **Order Events**: `CHECKOUT.ORDER.APPROVED`, `CHECKOUT.ORDER.COMPLETED`, etc.
- **Dispute Events**: `CUSTOMER.DISPUTE.CREATED`, `CUSTOMER.DISPUTE.RESOLVED`, etc.
- **Subscription Events**: `BILLING.SUBSCRIPTION.CREATED`, `BILLING.SUBSCRIPTION.CANCELLED`, etc.
- **Payout Events**: `PAYMENT.PAYOUTS.ITEM.SUCCEEDED`, etc.

See `Paypal.Webhook.EventTypes` for the complete list.

## Authentication & Token Management

The library uses **lazy authentication** - the OAuth token is obtained on the first API call, not at application startup. This enables:

- Runtime configuration without startup crashes
- Integration with parent libraries that manage their own config
- Dynamic credential switching

The token is automatically refreshed before expiration (when `:auto_refresh` is `true`).

## Error Handling

All functions return `{:ok, result}` on success or `{:error, error}` on failure.

**Configuration Errors:**
If PayPal is not configured, you'll get a clear error at request time:

```elixir
{:error, %ArgumentError{message: "PayPal client_id not configured..."}}
```

**API Errors:**
Structured errors via `Paypal.Common.Error` with details about what went wrong.

## Testing

The library includes comprehensive tests with mocked HTTP responses. Use the included test helpers for integration testing.

## Migration Notes

### From v0.1.0 to v0.2.0 (Lazy Config)

If you previously relied on compile-time config checking, note that:

1. **Config moved to runtime**: Use `config/runtime.exs` instead of `config/config.exs` for environment variables
2. **Use `System.fetch_env!/1`**: Instead of `System.get_env/1` to ensure variables are present
3. **No startup crashes**: Missing config won't crash the app on startup - errors occur at request time

```

## Key Changes Made:

1. **Added "Lazy Configuration" to features** - highlights the new pattern
2. **Three configuration methods** - Config files, runtime, and parent library patterns
3. **Changed `client_secret` to `secret`** - matches the actual config key used in the code
4. **Added configuration options table** - clear reference for all options
5. **Added "Authentication & Token Management" section** - explains lazy auth behavior
6. **Added "Migration Notes"** - for users upgrading from previous versions
7. **Updated error handling section** - mentions config errors at request time
8. **Recommended `config/runtime.exs`** instead of `config/config.exs` for env vars
9. **Added `System.fetch_env!/1` examples** - enforces env var presence
# Paypal

Paypal integration using [Tesla](https://github.com/elixir-tesla/tesla).

The aim of this library is to get completely covered the use of the Paypal API v2 for Orders, Payments, Authorization, and Webhooks.

## Features

- **Orders**: Create, authorize, capture, and manage PayPal orders
- **Payments**: Handle payment captures, refunds, and authorizations
- **Webhooks**: Receive real-time notifications about payment events
- **Authentication**: Automatic token management with refresh

## Installation

Add `paypal` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:paypal, "~> 0.1.0"}
  ]
end
```

## Configuration

Configure your PayPal credentials in `config/config.exs`:

```elixir
config :paypal,
  client_id: System.get_env("PAYPAL_CLIENT_ID"),
  client_secret: System.get_env("PAYPAL_CLIENT_SECRET"),
  url: "https://api.sandbox.paypal.com"  # or "https://api.paypal.com" for production
```

## Usage

### Orders

```elixir
# Create an order for capture
{:ok, order} = Paypal.Order.create(:capture, [
  %{"amount" => %{"currency_code" => "USD", "value" => "10.00"}}
], %{
  "return_url" => "https://example.com/success",
  "cancel_url" => "https://example.com/cancel"
})

# Authorize an order
{:ok, authorized} = Paypal.Order.authorize(order.id)

# Capture an order
{:ok, captured} = Paypal.Order.capture(order.id)
```

### Payments

```elixir
# Capture an authorization
{:ok, payment} = Paypal.Payment.capture("AUTHORIZATION_ID")

# Refund a payment
{:ok, refund} = Paypal.Payment.refund("CAPTURE_ID")

# Show payment details
{:ok, info} = Paypal.Payment.show("PAYMENT_ID")
```

### Webhooks

Webhooks allow your application to receive real-time notifications when events happen with your PayPal transactions.

#### Creating a Webhook

```elixir
{:ok, webhook} = Paypal.Webhook.create(%{
  url: "https://myapp.com/webhooks/paypal",
  event_types: ["PAYMENT.CAPTURE.COMPLETED", "CHECKOUT.ORDER.APPROVED"]
})
```

#### Listing Webhooks

```elixir
{:ok, webhooks} = Paypal.Webhook.list()
```

#### Verifying Webhook Signatures

For security, always verify webhook signatures to ensure they're authentic:

```elixir
# In your Phoenix controller
def handle_webhook(conn, params) do
  headers = Enum.into(conn.req_headers, %{})

  case Paypal.Webhook.verify_signature(params, headers) do
    {:ok, :verified} ->
      # Process the webhook
      handle_event(params)
      send_resp(conn, 200, "OK")

    {:error, reason} ->
      send_resp(conn, 400, "Invalid signature")
  end
end
```

#### Parsing Webhook Events

```elixir
{:ok, event} = Paypal.Webhook.parse_event(params)

# Check event type
if Paypal.Webhook.Event.payment_event?(event) do
  # Handle payment event
end

if Paypal.Webhook.Event.order_event?(event) do
  # Handle order event
end
```

#### Available Event Types

The library supports all PayPal webhook event types:

- **Payment Events**: `PAYMENT.CAPTURE.COMPLETED`, `PAYMENT.CAPTURE.DENIED`, etc.
- **Order Events**: `CHECKOUT.ORDER.APPROVED`, `CHECKOUT.ORDER.COMPLETED`, etc.
- **Dispute Events**: `CUSTOMER.DISPUTE.CREATED`, `CUSTOMER.DISPUTE.RESOLVED`, etc.
- **Subscription Events**: `BILLING.SUBSCRIPTION.CREATED`, `BILLING.SUBSCRIPTION.CANCELLED`, etc.
- **Payout Events**: `PAYMENT.PAYOUTS.ITEM.SUCCEEDED`, etc.

See `Paypal.Webhook.EventTypes` for the complete list.

## Error Handling

All functions return `{:ok, result}` on success or `{:error, error}` on failure. Errors are structured using `Paypal.Common.Error` with details about what went wrong.

## Testing

The library includes comprehensive tests with mocked HTTP responses. Use the included test helpers for integration testing.
