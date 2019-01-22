/*
* Copyright ⓒ 2019 Cassidy James Blaede (https://cassidyjames.com)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Cassidy James Blaede <c@ssidyjam.es>
*/

public class MainWindow : Gtk.Window {
    public string uri { get; construct set; }
    public SimpleActionGroup actions { get; construct; }

    public Gtk.Stack stack { get; construct set; }
    public WebKit.WebView web_view { get; construct set; }
    public Gtk.Stack refresh_stop_stack { get; construct set; }
    public Gtk.Button back_button { get; construct set; }
    public Gtk.Button forward_button { get; construct set; }
    public Gtk.Button refresh_button { get; construct set; }
    public Gtk.Button stop_button { get; construct set; }
    public Gtk.Entry url_entry { get; construct set; }
    public BrowserButton browser_button { get; construct set; }
    public Gtk.Button erase_button { get; construct set; }

    public MainWindow (Gtk.Application application, string? _uri = null) {
        Object (
            application: application,
            border_width: 0,
            icon_name: Ephemeral.instance.application_id,
            resizable: true,
            title: "Ephemeral",
            uri: _uri,
            window_position: Gtk.WindowPosition.CENTER
        );
    }

    construct {
        default_height = 800;
        default_width = 1280;

        var header = new Gtk.HeaderBar ();
        header.show_close_button = true;
        header.has_subtitle = false;

        var web_context = new WebKit.WebContext.ephemeral ();
        web_context.set_process_model (WebKit.ProcessModel.MULTIPLE_SECONDARY_PROCESSES);
        web_context.get_cookie_manager ().set_accept_policy (WebKit.CookieAcceptPolicy.NO_THIRD_PARTY);

        var web_kit_settings = new WebKit.Settings();
        web_kit_settings.allow_file_access_from_file_urls = true;
        web_kit_settings.default_font_family = Gtk.Settings.get_default().gtk_font_name;
        web_kit_settings.enable_java = false;
        web_kit_settings.enable_mediasource = true;
        web_kit_settings.enable_plugins = false;
        web_kit_settings.enable_smooth_scrolling = true;

        web_view = new WebKit.WebView.with_context (web_context);
        web_view.expand = true;
        web_view.height_request = 200;
        web_view.settings = web_kit_settings;

        back_button = new Gtk.Button.from_icon_name ("go-previous-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        back_button.sensitive = false;
        back_button.tooltip_text = "Back";
        back_button.tooltip_markup = Granite.markup_accel_tooltip ({"<Alt>Left"}, back_button.tooltip_text);

        forward_button = new Gtk.Button.from_icon_name ("go-next-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        forward_button.sensitive = false;
        forward_button.tooltip_text = "Forward";
        forward_button.tooltip_markup = Granite.markup_accel_tooltip ({"<Alt>Right"}, forward_button.tooltip_text);

        refresh_button = new Gtk.Button.from_icon_name ("view-refresh-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        refresh_button.tooltip_text = "Reload page";
        refresh_button.tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl>r"}, refresh_button.tooltip_text);

        stop_button = new Gtk.Button.from_icon_name ("process-stop-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        stop_button.tooltip_text = "Stop loading";

        refresh_stop_stack = new Gtk.Stack ();
        refresh_stop_stack.add (refresh_button);
        refresh_stop_stack.add (stop_button);
        refresh_stop_stack.visible_child = refresh_button;

        var new_window_button = new Gtk.Button.from_icon_name ("window-new", Gtk.IconSize.LARGE_TOOLBAR);
        new_window_button.tooltip_text = "Open new window";
        new_window_button.tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl>n"}, new_window_button.tooltip_text);

        url_entry = new UrlEntry (web_view);

        erase_button = new Gtk.Button.from_icon_name ("edit-delete", Gtk.IconSize.LARGE_TOOLBAR);
        erase_button.sensitive = false;
        erase_button.tooltip_text = "Erase browsing history";
        erase_button.tooltip_markup = Granite.markup_accel_tooltip ({"<Ctrl>W"}, erase_button.tooltip_text);

        browser_button = new BrowserButton (web_view);
        browser_button.sensitive = false;

        header.pack_start (back_button);
        header.pack_start (forward_button);
        header.pack_start (refresh_stop_stack);
        header.pack_end (browser_button);
        header.pack_end (new_window_button);
        header.pack_end (erase_button);

        header.custom_title = url_entry;

        var paid_info_bar = new PaidInfoBar ();
        var native_info_bar = new NativeInfoBar ();
        var default_info_bar = new DefaultInfoBar ();
        var network_info_bar = new NetworkInfoBar ();

        var welcome_view = new WelcomeView ();
        var error_view = new ErrorView ();

        stack = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        stack.add_named (welcome_view, "welcome-view");
        stack.add_named (web_view, "web-view");
        stack.add_named (error_view, "error-view");
        stack.visible_child_name = "welcome-view";

        var grid = new Gtk.Grid ();
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (paid_info_bar);
        grid.add (native_info_bar);
        grid.add (default_info_bar);
        grid.add (network_info_bar);
        grid.add (stack);

        set_titlebar (header);
        add (grid);

        show_all ();

        if (uri != null && uri != "") {
            web_view.load_uri (uri);
            stack.visible_child_name = "web-view";
        } else {
            url_entry.grab_focus ();
            stack.visible_child_name = "welcome-view";
        }

        back_button.clicked.connect (web_view.go_back);
        forward_button.clicked.connect (web_view.go_forward);
        refresh_button.clicked.connect (web_view.reload);
        stop_button.clicked.connect (web_view.stop_loading);

        new_window_button.clicked.connect (() => {
            new_window ();
        });

        erase_button.clicked.connect (erase);

        web_view.load_changed.connect (update_progress);
        web_view.notify["uri"].connect (update_progress);
        web_view.notify["estimated-load-progress"].connect (update_progress);
        web_view.notify["is-loading"].connect (update_progress);

        web_view.decide_policy.connect ((decision, type) => {
            switch (type) {
                case WebKit.PolicyDecisionType.NAVIGATION_ACTION:
                    stack.visible_child_name = "web-view";
                    var action = ((WebKit.NavigationPolicyDecision)decision).navigation_action;
                    string uri = action.get_request ().get_uri ();
                    if (action.is_user_gesture ()) {
                        // Middle- or ctrl-click
                        bool has_ctrl = (action.get_modifiers () & Gdk.ModifierType.CONTROL_MASK) != 0;
                        if (
                            action.get_mouse_button () == 2 ||
                            (has_ctrl && action.get_mouse_button () == 1)
                        ) {
                            new_window (uri);
                            decision.ignore ();
                            return true;
                        }
                    }
                    break;
                case WebKit.PolicyDecisionType.NEW_WINDOW_ACTION:
                    var action = ((WebKit.NavigationPolicyDecision)decision).navigation_action;
                    string uri = action.get_request ().get_uri ();

                    if (is_location (uri)) {
                        web_view.load_uri (uri);
                    } else {
                        return false;
                    }
                    decision.ignore ();
                    return true;
            }
            return false;
        });

        web_view.load_failed.connect ((load_event, uri, load_error) => {
            if (load_error is WebKit.PluginError.WILL_HANDLE_LOAD) {
                // A plugin will take over
                return false;
            } else if (load_error is WebKit.NetworkError.CANCELLED) {
                // Mostly initiated by JS redirects
                return false;
            } else if (load_error is WebKit.PolicyError.FRAME_LOAD_INTERRUPTED_BY_POLICY_CHANGE) {
                // A frame load is cancelled because of a download
                return false;
            } else if (load_error is WebKit.PolicyError.CANNOT_SHOW_URI) {
                open_externally (uri);
            } else {
                stack.visible_child_name = "error-view";
            }

            return true;
        });

        Ephemeral.settings.bind ("zoom", web_view, "zoom-level", SettingsBindFlags.DEFAULT);

        var accel_group = new Gtk.AccelGroup ();

        accel_group.connect (
            Gdk.Key.Left,
            Gdk.ModifierType.MOD1_MASK,
            Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
            () => {
                web_view.go_back ();
                return true;
            }
        );

        accel_group.connect (
            Gdk.Key.Right,
            Gdk.ModifierType.MOD1_MASK,
            Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
            () => {
                web_view.go_forward ();
                return true;
            }
        );

        accel_group.connect (
            Gdk.Key.R,
            Gdk.ModifierType.CONTROL_MASK,
            Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
            () => {
                web_view.reload ();
                return true;
            }
        );

        accel_group.connect (
            Gdk.Key.L,
            Gdk.ModifierType.CONTROL_MASK,
            Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
            () => {
                url_entry.grab_focus ();
                return true;
            }
        );

        accel_group.connect (
            Gdk.Key.W,
            Gdk.ModifierType.CONTROL_MASK,
            Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
            () => {
                erase ();
                return true;
            }
        );

        accel_group.connect (
            Gdk.Key.N,
            Gdk.ModifierType.CONTROL_MASK,
            Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
            () => {
                new_window ();
                return true;
            }
        );

        accel_group.connect (
            Gdk.Key.plus,
            Gdk.ModifierType.CONTROL_MASK,
            Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
            () => {
                zoom_in ();
                return true;
            }
        );

        accel_group.connect (
            Gdk.Key.equal,
            Gdk.ModifierType.CONTROL_MASK,
            Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
            () => {
                zoom_in ();
                return true;
            }
        );

        accel_group.connect (
            Gdk.Key.minus,
            Gdk.ModifierType.CONTROL_MASK,
            Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
            () => {
                zoom_out ();
                return true;
            }
        );

        accel_group.connect (
            Gdk.Key.@0,
            Gdk.ModifierType.CONTROL_MASK,
            Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
            () => {
                zoom_default ();
                return true;
            }
        );

        add_accel_group (accel_group);

        web_view.button_release_event.connect ((event) => {
            if (event.button == 8) {
                web_view.go_back ();
                return true;
            } else if (event.button == 9) {
                web_view.go_forward ();
                return true;
            }

            return false;
        });
    }

    private void update_progress () {
        back_button.sensitive = web_view.can_go_back ();
        forward_button.sensitive = web_view.can_go_forward ();

        browser_button.sensitive = true;
        erase_button.sensitive = true;

        if (web_view.is_loading) {
            refresh_stop_stack.visible_child = stop_button;
            web_view.bind_property ("estimated-load-progress", url_entry, "progress-fraction");
        } else {
            refresh_stop_stack.visible_child = refresh_button;
            url_entry.progress_fraction = 0;

            if (!url_entry.has_focus) {
                url_entry.text = web_view.get_uri ();
            }
        }
    }

    private void erase () {
        new_window ();
        close ();
    }

    public void new_window (string? uri = null) {
        var app_window = new MainWindow (application, uri);
        app_window.show_all ();
    }

    private void open_externally (string uri) {
        string protocol = uri.split ("://")[0];
        var external_dialog = new ExternalDialog (protocol);
        external_dialog.transient_for = (Gtk.Window) get_toplevel ();

        external_dialog.response.connect ((response_id) => {
            switch (response_id) {
                case Gtk.ResponseType.OK:
                    try {
                        Gtk.show_uri (get_screen (), uri, Gtk.get_current_event_time ());
                    } catch (GLib.Error e) {
                        critical (e.message);
                    }
                    external_dialog.close ();
                    break;
                case Gtk.ResponseType.CANCEL:
                case Gtk.ResponseType.CLOSE:
                case Gtk.ResponseType.DELETE_EVENT:
                    external_dialog.close ();
                    break;
                default:
                    assert_not_reached ();
            }
        });

        external_dialog.run ();

    }

    private bool is_location (string uri) {
        return
            uri.has_prefix ("about:") ||
            uri.has_prefix ("http://") ||
            uri.has_prefix ("https://") ||
            (uri.has_prefix ("data:") && (";" in uri)) ||
            uri.has_prefix ("javascript:");
    }

    private double zoom_in () {
        if (web_view.zoom_level < 5.0) {
            web_view.zoom_level = web_view.zoom_level + 0.1;
        } else {
            Gdk.beep ();
        }
        return web_view.zoom_level;
    }

    private double zoom_out () {
        if (web_view.zoom_level > 0.2) {
            web_view.zoom_level = web_view.zoom_level - 0.1;
        } else {
            Gdk.beep ();
        }
        return web_view.zoom_level;
    }

    private double zoom_default () {
        return web_view.zoom_level = 1.0;
    }
}

