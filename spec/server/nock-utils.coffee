nock = require('nock')
nockBack = nock.back
nockBack.fixtures = 'spec/fixtures/'

module.exports.setupNock = (fixtureFilename, done) ->
  nockBack.setMode('record')
  nockBack fixtureFilename, {afterRecord: afterRecord, before: before}, (nockDone) ->
    nock.enableNetConnect('localhost')
    done(null, nockDone)
      
module.exports.teardownNock = ->
  nockBack.setMode('wild')
  nock.cleanAll()

afterRecord = (scopes) ->
  scopes = _.filter scopes, (scope) -> not _.contains(scope.scope, '//localhost:')
  scopes = (_.pick(scope, 'scope', 'method', 'path', 'status', 'response') for scope in scopes)
  return scopes
  
# payment.spec.coffee needs this, because each test creates new Users with new _ids which
# are sent to Stripe as metadata. This messes up the tests which expect inputs to be
# uniform. This scope-preprocessor makes nock ignore body for matching requests.
# Ideally we would not do this; perhaps a better system would be to figure out a way
# to create users with consistent _id values.

costs = {
  before: 0
  after: 0
}

omitList = [
  'account_balance'
  'address_city'
  'address_country'
  'address_line1'
  'address_line1_check'
  'address_line2'
  'address_state'
  'address_zip'
  'address_zip_check'
  'alipay_accounts'
  'amount_off'
  'amount_refunded'
  'application_fee'
  'application_fee_percent'
  'balance_transaction'
  'brand'
  'canceled_at'
  'captured'
  'country'
  'created'
  'currency'
  'cvc_check'
  'default_source'
  'default_source_type'
  'delinquent'
  'destination'
  'dynamic_last4'
  'discount'
  'discountable'
  'dispute'
  'duration'
  'duration_in_months'
  'end'
  'ended_at'
  'exp_month'
  'exp_year'
  'failure_code'
  'failure_message'
  'fingerprint'
  'fraud_details'
  'funding'
  'interval'
  'interval_count'
  'invoice'
  'last4'
  'livemode'
  'max_redemptions'
  'name'
  'object'
  'percent_off'
  'receipt_email'
  'receipt_number'
  'redeem_by'
  'shipping'
  'slug'
  'start'
  'statement_descriptor'
  'status'
  'tax_percent'
  'times_redeemed'
  'tokenization_method'
  'total_count'
  'trial_end'
  'trial_period_days'
  'trial_start'
  'url'
  'valid'
  'charge'
  'payment'
  'starting_balance'
  'webhooks_delivered_at'
  'tax'
  'subtotal'
  'ending_balance'
  'forgiven'
  'next_payment_attempt'
  'period_end'
  'period_start'
  'date'
  'closed'
  'attempted'
  'attempt_count'
  'amount_due'
  'used'
  'client_ip'
  'refunded'
  'userID'
  'message'
  'original_purchase_date'
  'original_purchsae_date_ms'
  'original_purchase_date_pst'
  'code'
  'is_trial_period'
  'purchase_date_pst'
  'purchase_date_ms'
  'purchase_date'
  'original_transaction_id'
  'decline_code'
  'param'
  'maxRedeemers'
  'original_application_version'
  'request_date_pst'
  'request_date_ms'
  'request_date'
  'receipt_creation_date_pst'
  'receipt_creation_date_ms'
  'receipt_creation_date'
  'version_external_identifier'
  'download_id'
  'application_version'
  'original_purchase_date_ms'
  'bundle_id'
  'app_item_id'
  'adam_id'
  'receipt_type'
  'environment'
  'deleted'
  'months'
]

keep = {
  # specific tests
  has_more: true
  email: true
  subscription: true
  description: true
  current_period_end: true
  current_period_start: true
  cancel_at_period_end: true
  productID: true
  
  # throughout
  gems: true
  total: true
  proration: true
  paid: true
  id: true
  customer: true
  amount: true
  quantity: true
  type: true
  timestamp: true
  transaction_id: true
  product_id: true
}

totals = {}

clean = (obj) ->
  for key in omitList
    unless _.isArray(obj[key]) or _.isObject(obj[key])
      delete obj[key]
  for key, value of obj
    if _.isNull(value)
      delete obj[key]
    if _.isArray(value)
      for obj in value
        clean(obj)
      if _.isEmpty(value)
        delete obj[key]
    else if _.isObject(value)
      clean(value)
      if _.isEmpty(value)
        delete obj[key]
    else unless keep[key]
      totals[key] ?= 0
      totals[key] += 1

before = (scope) ->
  costs.before += JSON.stringify(scope, null, '\t').length
  delete scope['headers']
  delete scope['body']
  clean(scope.response)
  costs.after += JSON.stringify(scope, null, '\t').length
  console.log 'costs', costs, (100 * costs.after / costs.before).toFixed(2)
  console.log JSON.stringify(scope, null, '\t')
  console.log _.sortBy _.pairs(totals), (pair) -> pair[1]
  scope.body = (body) -> true
  
