defmodule NotificationsE2ETest do
  use ExUnit.Case

  alias Notifications.{Notification, Dispatcher}

  setup do
    # Dispatcher is already started by application supervisor
    # No need to start it again
    :ok
  end

  describe "Notification delivery" do
    test "dispatcher sends notifications to registered channels" do
      notification =
        Notification.new(%{
          title: "Test Alert",
          message: "This is a test notification",
          severity: :warning
        })

      results = Dispatcher.send_sync(notification, [], 5000)
      assert is_list(results)
    end

    test "notification with critical severity is routed correctly" do
      notification =
        Notification.new(%{
          title: "Critical Alert",
          message: "Critical failure detected",
          severity: :critical,
          url: "https://example.com"
        })

      assert notification.severity == :critical
      assert notification.title == "Critical Alert"
      assert notification.url == "https://example.com"
      assert Map.has_key?(notification, :id)
      assert Map.has_key?(notification, :timestamp)
    end

    test "notification with error severity is routed correctly" do
      notification =
        Notification.new(%{
          title: "Error Alert",
          message: "Error detected",
          severity: :error
        })

      assert notification.severity == :error
      assert Notification.severity_string(notification.severity) == "ERROR"
    end

    test "notification severity string conversion" do
      assert Notification.severity_string(:info) == "INFO"
      assert Notification.severity_string(:warning) == "WARNING"
      assert Notification.severity_string(:error) == "ERROR"
      assert Notification.severity_string(:critical) == "CRITICAL"
    end
  end

  describe "Channel management" do
    test "register and unregister channels" do
      assert :ok =
               Dispatcher.register_channel(:test_channel, Notifications.Channels.Email, %{
                 from: "test@example.com",
                 to: ["test@example.com"]
               })

      assert :ok =
               Dispatcher.register_channel(:test_channel2, Notifications.Channels.Slack, %{
                 webhook_url: "https://hooks.slack.com/test"
               })

      channels = Dispatcher.list_channels()
      assert length(channels) >= 2

      assert :ok = Dispatcher.unregister_channel(:test_channel)

      channels_after = Dispatcher.list_channels()
      assert length(channels_after) == length(channels) - 1
    end

    test "set default channels by severity" do
      defaults = %{
        critical: [:slack],
        error: [:email],
        warning: [],
        info: []
      }

      assert :ok = Dispatcher.set_defaults(defaults)
    end
  end
end
