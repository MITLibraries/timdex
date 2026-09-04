class GraphqlController < ApplicationController
  skip_before_action :verify_authenticity_token

  def execute
    @graphql_search_events = []
    variables = ensure_hash(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = {
      # Query context goes here, for example:
      # current_user: current_user,
      request_id: request.request_id,
      graphql_search_events: @graphql_search_events
    }
    result = TimdexSchema.execute(query, variables: variables,
                                         context: context,
                                         operation_name: operation_name)
    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?

    handle_error_in_development e
  end

  private

  # Handle form data, JSON body, or a blank value
  def ensure_hash(ambiguous_param)
    case ambiguous_param
    when String
      if ambiguous_param.present?
        ensure_hash(JSON.parse(ambiguous_param))
      else
        {}
      end
    when Hash, ActionController::Parameters
      ambiguous_param
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{ambiguous_param}"
    end
  end

  def handle_error_in_development(err)
    logger.error err.message
    logger.error err.backtrace.join("\n")

    render json: { error: { message: err.message, backtrace: err.backtrace },
                   data: {} }, status: :internal_server_error
  end

  # Appends additional information to the log payload that is specific to GraphQL requests
  def append_info_to_payload(payload)
    super

    return if @graphql_search_events.blank?

    payload[:graphql_search_events] = @graphql_search_events
    payload.merge!(@graphql_search_events.first) if @graphql_search_events.one?
  end
end
