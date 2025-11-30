# Helper resources for testing

# Define api_store_resource subclass for testing
api_store_resource <- R6::R6Class(
  classname = "api_store_resource",
  inherit = api_resource,
  private = list(
    endpoint = "store"
  ),
  public = list(
    #' @description Get an order by ID
    #' @param order_id The order ID to retrieve
    get_order = function(order_id) {
      self$.client$.fetch(
        path = "/order/{orderId}",
        orderId = order_id,
        req_method = "get",
        content = "body"
      )
    },
    #' @description Create a new order
    #' @param order_data List containing order details
    create_order = function(order_data) {
      self$.client$.fetch(
        path = "/order",
        req_data = order_data,
        req_method = "post",
        content = "body"
      )
    }
  )
)
