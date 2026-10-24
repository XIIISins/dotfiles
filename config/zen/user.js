// Zen reapplies these on every start, so a change made in settings for one of
// them is undone at the next launch. Allowlist only: prefs.js is mostly app
// state (ids, timestamps, migrations), so never copy it in here.

// new tab shows Zen's new tab page (and a new tab extension) instead of the floating url bar
user_pref("zen.urlbar.replace-newtab", false);

// compact mode on at startup, tabs bar hidden until hovered
user_pref("zen.view.compact.enable-at-startup", true);

// no new tab button in the vertical tab list
user_pref("zen.tabs.show-newtab-vertical", false);

// swipe gestures at the default speed
user_pref("zen.swipe.is-fast-swipe", false);

// sidebar hides when closed
user_pref("sidebar.visibility", "hide-on-close");

// clear form data on shutdown
user_pref("privacy.clearOnShutdown_v2.formdata", true);
