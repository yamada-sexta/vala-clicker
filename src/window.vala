using Gtk;
using Adw;

namespace Clicker {
    public class Window : Adw.ApplicationWindow {
        private int count = 0;
        private double clicks_per_second = 0.0;
        private int click_power = 1;

        private Label count_label;
        private Label cps_label;
        private DebugWindow debug_window;
        private Upgrade[] upgrades;

        public Window (Adw.Application app) {
            Object (application: app, title: "Vala Clicker");

            this.set_default_size (600, 400);

            var toolbar_view = new Adw.ToolbarView ();
            this.set_content (toolbar_view);

            var header = new Adw.HeaderBar ();
            toolbar_view.add_top_bar (header);

            var main_box = new Box (Orientation.HORIZONTAL, 0);
            toolbar_view.set_content (main_box);

            // Left panel: Clicking area
            var click_panel = new Box (Orientation.VERTICAL, 24);
            click_panel.set_hexpand (true);
            click_panel.set_margin_top (48);
            click_panel.set_margin_bottom (48);
            click_panel.set_margin_start (48);
            click_panel.set_margin_end (48);
            click_panel.set_valign (Align.CENTER);

            count_label = new Label (count.to_string ());
            count_label.add_css_class ("title-1");
            count_label.add_css_class ("numeric");
            count_label.margin_top = 32;
            count_label.margin_bottom = 32;

            cps_label = new Label ("0 CPS");
            cps_label.add_css_class ("caption");

            var click_button = new Button ();
            var content = new Adw.ButtonContent ();
            content.icon_name = "list-add-symbolic";
            content.label = "Click Me!";
            click_button.set_child (content);
            click_button.add_css_class ("suggested-action");
            click_button.add_css_class ("pill");
            click_button.set_size_request (150, 150);
            click_button.clicked.connect (on_click_clicked);

            click_panel.append (count_label);
            click_panel.append (cps_label);
            click_panel.append (click_button);

            // Right panel: Upgrades & Console
            var sidebar_box = new Box (Orientation.VERTICAL, 12);
            sidebar_box.width_request = 250;
            sidebar_box.set_margin_top (12);
            sidebar_box.set_margin_bottom (12);
            sidebar_box.set_margin_start (12);
            sidebar_box.set_margin_end (12);
 
             var upgrade_title = new Label ("Upgrades");
             upgrade_title.add_css_class ("title-4");
             sidebar_box.append (upgrade_title);
 
             var scrolled = new ScrolledWindow ();
             scrolled.set_vexpand (true);
             sidebar_box.append (scrolled);
 
             var upgrade_list = new Box (Orientation.VERTICAL, 6);
             scrolled.set_child (upgrade_list);
 
            init_upgrades (upgrade_list);

            main_box.append (click_panel);
            main_box.append (new Separator (Orientation.VERTICAL));
            main_box.append (sidebar_box);

            // F11 Toggle for console via Action
            var action = new SimpleAction ("toggle-console", null);
            action.activate.connect (() => {
                if (debug_window == null) {
                    debug_window = new DebugWindow (this);
                }
                debug_window.present ();
            });
            this.add_action (action);

            var controller = new ShortcutController ();
            var trigger = ShortcutTrigger.parse_string ("F11");
            var shortcut_action = ShortcutAction.parse_string ("action(win.toggle-console)");
            var shortcut = new Shortcut (trigger, shortcut_action);
            controller.add_shortcut (shortcut);
            this.add_controller (controller);

            // Auto-click timer (every 100ms for smoothness)
            Timeout.add (100, () => {
                if (clicks_per_second > 0) {
                    add_clicks (clicks_per_second / 10.0);
                }
                return true;
            });
            
            print ("Window initialized successfully\n");
        }

        private void init_upgrades (Box container) {
            upgrades = {
                new Upgrade ("Auto Clicker", "Clicks once per second", 15, 1.15, UpgradeType.AUTO_CLICK, 1.0),
                new Upgrade ("Better Mouse", "Gain +1 click power", 50, 1.5, UpgradeType.CLICK_MULTIPLIER, 1.0),
                new Upgrade ("Mega Clicker", "Adds 10 clicks per second", 100, 1.15, UpgradeType.AUTO_CLICK, 10.0)
            };

            foreach (var upgrade in upgrades) {
                var row = new UpgradeRow (upgrade);
                row.purchased.connect (() => {
                    if (count >= upgrade.get_current_cost ()) {
                        count -= upgrade.get_current_cost ();
                        upgrade.purchase ();
                        apply_upgrade (upgrade);
                        row.update ();
                        update_labels ();
                    }
                });
                container.append (row);
            }
        }

        private void apply_upgrade (Upgrade upgrade) {
            if (upgrade.upgrade_type == UpgradeType.AUTO_CLICK) {
                clicks_per_second += upgrade.value;
            } else if (upgrade.upgrade_type == UpgradeType.CLICK_MULTIPLIER) {
                click_power += (int) upgrade.value;
            }
        }

        public void execute_command (string cmd_in) {
            var cmd = cmd_in.strip ();
            stdout.printf ("Debug Console: Executing command: %s\n", cmd);
            
            if (cmd.has_prefix ("/")) {
                var parts = cmd.substring (1).split (" ");
                if (parts.length >= 2 && parts[0] == "add_clicks") {
                    int amount = int.parse (parts[1]);
                    count += amount;
                    update_labels ();
                } else if (parts.length >= 2 && parts[0] == "set_cps") {
                    clicks_per_second = double.parse (parts[1]);
                    update_labels ();
                } else if (parts[0] == "reset") {
                    count = 0;
                    clicks_per_second = 0;
                    click_power = 1;
                    foreach (var upgrade in upgrades) {
                        // Resetting upgrades would need level reset in Upgrade class
                    }
                    update_labels ();
                }
            }
        }

        private void on_click_clicked () {
            add_clicks (click_power);
        }

        private double partial_clicks = 0.0;
        private void add_clicks (double val) {
            partial_clicks += val;
            if (partial_clicks >= 1.0) {
                int integral = (int) partial_clicks;
                count += integral;
                partial_clicks -= integral;
                update_labels ();
            }
        }

        private void update_labels () {
            if (count_label != null)
                count_label.set_label (count.to_string ());
            if (cps_label != null)
                cps_label.set_label ("%.1f CPS".printf (clicks_per_second));
        }
    }

    public class UpgradeRow : Box {
        private Upgrade upgrade;
        private Button buy_button;

        public signal void purchased ();

        public UpgradeRow (Upgrade upgrade) {
            Object (orientation: Orientation.VERTICAL, spacing: 4);
            this.upgrade = upgrade;

            this.set_margin_top (8);
            this.set_margin_bottom (8);
            this.set_margin_start (8);
            this.set_margin_end (8);

            var title_label = new Label (upgrade.name);
            title_label.set_halign (Align.START);
            title_label.add_css_class ("bold");

            var desc_label = new Label (upgrade.description);
            desc_label.set_halign (Align.START);
            desc_label.add_css_class ("caption");
            desc_label.set_wrap (true);

            buy_button = new Button.with_label ("Buy (%d)".printf (upgrade.get_current_cost ()));
            buy_button.clicked.connect (() => {
                purchased ();
            });

            this.append (title_label);
            this.append (desc_label);
            this.append (buy_button);
        }

        public void update () {
            buy_button.set_label ("Buy (%d)".printf (upgrade.get_current_cost ()));
        }
    }

    public class DebugWindow : Gtk.Window {
        private Window main_window;
        private Entry entry;

        public DebugWindow (Window main) {
            Object (title: "Debug Console", transient_for: main, modal: false);
            this.main_window = main;
            this.set_default_size (300, 100);

            var box = new Box (Orientation.VERTICAL, 12);
            box.margin_top = 12;
            box.margin_bottom = 12;
            box.margin_start = 12;
            box.margin_end = 12;

            entry = new Entry ();
            entry.placeholder_text = "Enter command...";
            entry.activate.connect (() => {
                main_window.execute_command (entry.text);
                entry.text = "";
            });

            box.append (entry);
            this.set_child (box);
        }
    }
}
