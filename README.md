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
