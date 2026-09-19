//@ pragma UseQApplication

import Quickshell

import "bar" as Bar

Scope {
  Bar.Notifications {
    id: notifications
  }

  Bar.Bar {
    notifications: notifications
  }
}
