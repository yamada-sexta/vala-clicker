using GLib;

namespace Clicker {
    public enum UpgradeType {
        AUTO_CLICK,
        CLICK_MULTIPLIER,
        CPS_MULTIPLIER
    }

    public class Requirement : Object {
        public Upgrade required_upgrade { get; construct; }
        public int required_level { get; construct; }

        public Requirement (Upgrade upgrade, int level) {
            Object (required_upgrade: upgrade, required_level: level);
        }

        public bool is_met () {
            return required_upgrade.level >= required_level;
        }
    }

    public class Upgrade : Object {
        public string name { get; set; }
        public string description { get; set; }
        public double base_cost { get; set; }
        public double cost_multiplier { get; set; }
        public UpgradeType upgrade_type { get; set; }
        public double value { get; set; }

        public int level { get; set; default = 0; }
        public Requirement[] requirements { get; set; default = {}; }

        public Upgrade (string name, string description, double base_cost, double cost_multiplier, UpgradeType type, double value, Requirement[] requirements = {}) {
            Object (
                name: name,
                description: description,
                base_cost: base_cost,
                cost_multiplier: cost_multiplier,
                upgrade_type: type,
                value: value
            );
            this.requirements = requirements;
        }

        public double get_current_cost () {
            return base_cost * Math.pow (cost_multiplier, level);
        }

        public void purchase () {
            level++;
        }

        public bool is_unlocked (int player_level) {
            foreach (var req in requirements) {
                if (!req.is_met ()) {
                    return false;
                }
            }
            return true;
        }
    }

    public class Progression : Object {
        public double count { get; private set; default = 0.0; }
        public double total_clicks_ever { get; private set; default = 0.0; }
        public int level { get; private set; default = 1; }
        public double xp { get; private set; default = 0.0; }
        public double xp_to_next_level { get; private set; default = 100.0; }

        public double clicks_per_second { get; private set; default = 0.0; }
        public int click_power { get; private set; default = 1; }
        public double global_multiplier { get; private set; default = 1.0; }

        public Upgrade[] upgrades { get; private set; }

        public signal void updated ();
        public signal void leveled_up (int old_level, int new_level);

        public Progression () {
            init_upgrades ();
            recalculate_stats ();
        }

        private void init_upgrades () {
            var auto_clicker = new Upgrade ("Auto Clicker", "Clicks once per second", 15.0, 1.15, UpgradeType.AUTO_CLICK, 1.0);
            var better_mouse = new Upgrade ("Better Mouse", "Gain +1 click power", 50.0, 1.5, UpgradeType.CLICK_MULTIPLIER, 1.0);
            
            var cursor_farm = new Upgrade ("Cursor Farm", "Adds 5 clicks per second", 150.0, 1.15, UpgradeType.AUTO_CLICK, 5.0, {
                new Requirement (auto_clicker, 10)
            });

            var click_lab = new Upgrade ("Click Laboratory", "Gain +5 click power", 400.0, 1.5, UpgradeType.CLICK_MULTIPLIER, 5.0, {
                new Requirement (better_mouse, 5)
            });

            var robot_army = new Upgrade ("Robot Army", "Adds 25 clicks per second", 1000.0, 1.15, UpgradeType.AUTO_CLICK, 25.0, {
                new Requirement (cursor_farm, 10)
            });

            var quantum_mouse = new Upgrade ("Quantum Mouse", "Gain +50 click power", 5000.0, 1.5, UpgradeType.CLICK_MULTIPLIER, 50.0, {
                new Requirement (click_lab, 5)
            });

            var factory = new Upgrade ("Click Factory", "Multiplies all CPS by 1.2x", 10000.0, 2.0, UpgradeType.CPS_MULTIPLIER, 0.2, {
                new Requirement (robot_army, 5)
            });

            upgrades = { auto_clicker, better_mouse, cursor_farm, click_lab, robot_army, quantum_mouse, factory };
        }

        public void add_clicks (double val, bool manual = false) {
            double amount = val * global_multiplier;
            count += amount;
            total_clicks_ever += amount;
            
            // Gain XP: 10% of click value for manual, 1% for auto
            add_xp (amount * (manual ? 0.1 : 0.01));
            
            updated ();
        }

        private void add_xp (double val) {
            xp += val;
            while (xp >= xp_to_next_level) {
                xp -= xp_to_next_level;
                level++;
                xp_to_next_level *= 1.2; // Increase requirement for next level
                
                recalculate_stats ();
                leveled_up (level - 1, level);
            }
        }

        public void purchase_upgrade (Upgrade upgrade) {
            double cost = upgrade.get_current_cost ();
            if (count >= cost) {
                count -= cost;
                upgrade.purchase ();
                recalculate_stats ();
                updated ();
            }
        }

        public void recalculate_stats () {
            double base_cps = 0.0;
            int base_power = 1;
            double cps_mult = 1.0;

            // Level bonus: 1% global multiplier per level
            global_multiplier = 1.0 + (level - 1) * 0.01;

            foreach (var up in upgrades) {
                if (up.level > 0) {
                    switch (up.upgrade_type) {
                        case UpgradeType.AUTO_CLICK:
                            base_cps += up.value * up.level;
                            break;
                        case UpgradeType.CLICK_MULTIPLIER:
                            base_power += (int) (up.value * up.level);
                            break;
                        case UpgradeType.CPS_MULTIPLIER:
                            cps_mult += up.value * up.level;
                            break;
                    }
                }
            }

            clicks_per_second = base_cps * cps_mult;
            click_power = base_power;
        }

        public void execute_debug_command (string cmd) {
            var parts = cmd.split (" ");
            if (parts.length >= 2 && parts[0] == "add_clicks") {
                count += double.parse (parts[1]);
            } else if (parts.length >= 2 && parts[0] == "set_level") {
                level = int.parse (parts[1]);
                xp = 0;
                xp_to_next_level = 100.0 * Math.pow (1.2, level - 1);
                recalculate_stats ();
            } else if (parts[0] == "reset") {
                count = 0;
                total_clicks_ever = 0;
                level = 1;
                xp = 0;
                xp_to_next_level = 100.0;
                foreach (var up in upgrades) up.level = 0;
                recalculate_stats ();
            }
            updated ();
        }
    }
}
