using Gtk;
using Adw;
using Gdk;

namespace Clicker {
    public class Window : Adw.ApplicationWindow {
        private Progression progression;
        private UpgradeRow[] upgrade_rows;
        private Label count_label;
        private Label cps_label;
        private Label level_label;
        private ProgressBar xp_bar;
        private Button click_button;
        private Overlay click_overlay;
        private Fixed click_effects_fixed;
        private DebugWindow debug_window;

        public Window (Adw.Application app) {
            Object (application: app, title: "Vala Clicker", icon_name: "com.github.yamada.vala-clicker");

            this.set_default_size (600, 400);

            var toolbar_view = new Adw.ToolbarView ();
            this.set_content (toolbar_view);

            var css_provider = new Gtk.CssProvider ();
            css_provider.load_from_data ("""
                .clicked {
                    transition: transform 0.05s ease-out;
                    transform: scale(0.95);
                }
                .pulse {
                    transition: transform 0.1s ease-out;
                    transform: scale(1.1);
                }
            """.data);
            Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

            var header = new Adw.HeaderBar ();
            toolbar_view.add_top_bar (header);

            var menu_button = new MenuButton ();
            menu_button.icon_name = "open-menu-symbolic";
            
            var menu = new GLib.Menu ();
            menu.append ("About Vala Clicker", "win.show-about");
            menu_button.menu_model = menu;
            
            header.pack_end (menu_button);

            var about_action = new GLib.SimpleAction ("show-about", null);
            about_action.activate.connect (() => {
                show_about ();
            });
            this.add_action (about_action);

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

            progression = new Progression ();
            progression.updated.connect (update_labels);
            progression.leveled_up.connect (on_leveled_up);

            count_label = new Label ("0");
            count_label.add_css_class ("title-1");
            count_label.add_css_class ("numeric");
            count_label.margin_top = 16;

            level_label = new Label ("Level 1");
            level_label.add_css_class ("title-4");
            level_label.add_css_class ("dim-label");

            xp_bar = new ProgressBar ();
            xp_bar.set_margin_start (48);
            xp_bar.set_margin_end (48);
            xp_bar.set_fraction (0.0);

            cps_label = new Label ("0 CPS");
            cps_label.add_css_class ("caption");
            cps_label.margin_bottom = 24;

            click_panel.append (level_label);
            click_panel.append (count_label);
            click_panel.append (xp_bar);
            click_panel.append (cps_label);

            click_overlay = new Overlay ();
            click_button = new Button ();
            var content = new Adw.ButtonContent ();
            content.icon_name = "list-add-symbolic";
            content.label = "Click Me!";
            click_button.set_child (content);
            click_button.add_css_class ("suggested-action");
            click_button.add_css_class ("pill");
            click_button.set_size_request (150, 150);
            click_button.clicked.connect (on_click_clicked);

            click_overlay.set_child (click_button);

            click_effects_fixed = new Fixed ();
            click_effects_fixed.can_target = false;
            click_overlay.add_overlay (click_effects_fixed);

            click_panel.append (click_overlay);

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

            var key_controller = new EventControllerKey ();
            key_controller.key_pressed.connect ((keyval, keycode, state) => {
                if (keyval == Gdk.Key.F11) {
                    this.activate_action ("toggle-console", null);
                    return true;
                }
                return false;
            });
            toolbar_view.add_controller (key_controller);

            // Auto-click timer (every 100ms for smoothness)
            Timeout.add (100, () => {
                if (progression.clicks_per_second > 0) {
                    progression.add_clicks (progression.clicks_per_second / 10.0);
                }
                return true;
            });
            
            print ("Window initialized successfully\n");
        }

        private void show_about () {
            var about = new Adw.AboutDialog () {
                application_name = "Vala Clicker",
                developer_name = "Yamada",
                license_type = Gtk.License.LGPL_3_0_ONLY,
                comments = "A fancy clicker game built with Vala and Libadwaita.",
                website = "https://github.com/yamada/vala-clicker",
                copyright = "© 2026 Yamada",
                application_icon = "com.github.yamada.vala-clicker"
            };
            about.present (this);
        }

        private void init_upgrades (Box container) {
            foreach (var upgrade in progression.upgrades) {
                var row = new UpgradeRow (upgrade);
                row.purchased.connect (() => {
                    progression.purchase_upgrade (upgrade);
                    foreach (var r in upgrade_rows) {
                        r.update (progression.level);
                    }
                });
                container.append (row);
                upgrade_rows += row;
                row.update (progression.level);
            }
        }

        public void execute_command (string cmd_in) {
            var cmd = cmd_in.strip ();
            stdout.printf ("Debug Console: Executing command: %s\n", cmd);
            
            if (cmd.has_prefix ("/")) {
                progression.execute_debug_command (cmd.substring (1));
            }
        }

        private void on_leveled_up (int old_level, int new_level) {
            spawn_floating_text (0, "LEVEL UP!");
            // Pulse the level label
            level_label.add_css_class ("pulse");
            Timeout.add (500, () => {
                level_label.remove_css_class ("pulse");
                return false;
            });
        }

        private void on_click_clicked () {
            progression.add_clicks (progression.click_power, true);
            animate_button ();
            spawn_floating_text (progression.click_power);
        }

        private void animate_button () {
            click_button.add_css_class ("clicked");
            Timeout.add (100, () => {
                click_button.remove_css_class ("clicked");
                return false;
            });
        }

        private void spawn_floating_text (int amount, string? custom_text = null) {
            var label = new Label (custom_text ?? "+%d".printf (amount));
            label.add_css_class ("title-2");
            label.add_css_class ("accent");
            label.can_target = false;
            
            double start_x = click_button.get_width() / 2 + (Random.next_double () - 0.5) * 60;
            double start_y = click_button.get_height() / 2;
            
            click_effects_fixed.put (label, start_x, start_y);

            var anim = new Adw.TimedAnimation (label, 0, -100, 1000,
                new Adw.CallbackAnimationTarget ((val) => {
                    click_effects_fixed.move (label, start_x, start_y + val);
                    label.opacity = (float) (1.0 - (Math.fabs (val) / 100.0));
                })
            );
            
            anim.done.connect (() => {
                click_effects_fixed.remove (label);
            });
            
            anim.play ();
        }

        private void update_labels () {
            if (count_label != null) {
                count_label.set_label ("%d".printf ((int) progression.count));
                count_label.add_css_class ("pulse");
                Timeout.add (100, () => {
                    count_label.remove_css_class ("pulse");
                    return false;
                });
            }
            if (level_label != null) {
                level_label.set_label ("Level %d".printf (progression.level));
            }
            if (xp_bar != null) {
                xp_bar.set_fraction (progression.xp / progression.xp_to_next_level);
            }
            if (cps_label != null)
                cps_label.set_label ("%.1f CPS (x%.2f)".printf (progression.clicks_per_second, progression.global_multiplier));
            
            if (upgrade_rows != null) {
                foreach (var row in upgrade_rows) {
                    row.update (progression.level);
                }
            }
        }
    }

    public class UpgradeRow : Box {
        private Upgrade upgrade;
        private Label level_label;
        private Button buy_button;

        public signal void purchased ();

        public UpgradeRow (Upgrade upgrade) {
            Object (orientation: Orientation.VERTICAL, spacing: 4);
            this.upgrade = upgrade;

            this.set_margin_top (8);
            this.set_margin_bottom (8);
            this.set_margin_start (8);
            this.set_margin_end (8);

            var title_box = new Box (Orientation.HORIZONTAL, 8);
            var title_label = new Label (upgrade.name);
            title_label.set_halign (Align.START);
            title_label.set_hexpand (true);
            title_label.add_css_class ("bold");

            level_label = new Label ("Lv 0");
            level_label.set_halign (Align.END);
            level_label.add_css_class ("caption");
            level_label.add_css_class ("dim-label");

            title_box.append (title_label);
            title_box.append (level_label);

            var desc_label = new Label (upgrade.description);
            desc_label.set_halign (Align.START);
            desc_label.add_css_class ("caption");
            desc_label.set_wrap (true);

            buy_button = new Button.with_label ("Buy (%d)".printf ((int) upgrade.get_current_cost ()));
            buy_button.clicked.connect (() => {
                purchased ();
            });

            this.append (title_box);
            this.append (desc_label);
            this.append (buy_button);
        }

        public void update (int player_level) {
            buy_button.set_label ("Buy (%d)".printf ((int) upgrade.get_current_cost ()));
            level_label.set_label ("Lv %d".printf (upgrade.level));
            this.visible = upgrade.is_unlocked (player_level);
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
