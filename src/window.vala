using Gtk;
using Adw;

namespace Clicker {
    public class Window : Adw.ApplicationWindow {
        private int count = 0;
        private double clicks_per_second = 0.0;
        private int click_power = 1;

        private Label count_label;
        private Label cps_label;
        private GenericArray<Upgrade> upgrades;

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
            count_label.set_css_classes ({"title-1", "numeric"});
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

            // Right panel: Upgrades
            var upgrade_panel = new Box (Orientation.VERTICAL, 12);
            upgrade_panel.width_request = 250;
            upgrade_panel.set_margin_top (12);
            upgrade_panel.set_margin_bottom (12);
            upgrade_panel.set_margin_start (12);
            upgrade_panel.set_margin_end (12);

            var upgrade_title = new Label ("Upgrades");
            upgrade_title.add_css_class ("title-4");
            upgrade_panel.append (upgrade_title);

            var scrolled = new ScrolledWindow ();
            scrolled.set_vexpand (true);
            upgrade_panel.append (scrolled);

            var upgrade_list = new Box (Orientation.VERTICAL, 6);
            scrolled.set_child (upgrade_list);

            main_box.append (click_panel);
            main_box.append (new Separator (Orientation.VERTICAL));
            main_box.append (upgrade_panel);

            init_upgrades (upgrade_list);

            // Auto-click timer (every 100ms for smoothness)
            Timeout.add (100, () => {
                if (clicks_per_second > 0) {
                    add_clicks (clicks_per_second / 10.0);
                }
                return true;
            });
        }

        private void init_upgrades (Box container) {
            upgrades = new GenericArray<Upgrade> ();
            upgrades.add (new Upgrade ("Auto Clicker", "Clicks once per second", 15, 1.15, UpgradeType.AUTO_CLICK, 1.0));
            upgrades.add (new Upgrade ("Better Mouse", "Gain +1 click power", 50, 1.5, UpgradeType.CLICK_MULTIPLIER, 1.0));
            upgrades.add (new Upgrade ("Mega Clicker", "Adds 10 clicks per second", 100, 1.15, UpgradeType.AUTO_CLICK, 10.0));

            foreach (var upgrade in upgrades) {
                var row = create_upgrade_row (upgrade);
                container.append (row);
            }
        }

        private Widget create_upgrade_row (Upgrade upgrade) {
            var box = new Box (Orientation.VERTICAL, 4);
            box.set_margin_top (8);
            box.set_margin_bottom (8);
            box.set_margin_start (8);
            box.set_margin_end (8);

            var title_label = new Label (upgrade.name);
            title_label.set_halign (Align.START);
            title_label.add_css_class ("bold");

            var desc_label = new Label (upgrade.description);
            desc_label.set_halign (Align.START);
            desc_label.add_css_class ("caption");
            desc_label.set_wrap (true);

            var buy_button = new Button.with_label ("Buy (%d)".printf (upgrade.get_current_cost ()));
            buy_button.clicked.connect (() => {
                if (count >= upgrade.get_current_cost ()) {
                    count -= upgrade.get_current_cost ();
                    upgrade.purchase ();
                    apply_upgrade (upgrade);
                    buy_button.set_label ("Buy (%d)".printf (upgrade.get_current_cost ()));
                    update_labels ();
                }
            });

            box.append (title_label);
            box.append (desc_label);
            box.append (buy_button);

            return box;
        }

        private void apply_upgrade (Upgrade upgrade) {
            if (upgrade.upgrade_type == UpgradeType.AUTO_CLICK) {
                clicks_per_second += upgrade.value;
            } else if (upgrade.upgrade_type == UpgradeType.CLICK_MULTIPLIER) {
                click_power += (int) upgrade.value;
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
            count_label.set_label (count.to_string ());
            cps_label.set_label ("%.1f CPS".printf (clicks_per_second));
        }
    }
}
