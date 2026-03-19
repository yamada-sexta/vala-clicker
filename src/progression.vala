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
        public double xp_to_next_level { get; private set; default = 50.0; } // Lowered starting XP for a faster early game

        public double clicks_per_second { get; private set; default = 0.0; }
        public double click_power { get; private set; default = 1.0; }
        public double global_multiplier { get; private set; default = 1.0; }

        public Upgrade[] upgrades { get; private set; }

        public signal void updated ();
        public signal void leveled_up (int old_level, int new_level);

        private string save_file_path;

        public Progression () {
            init_save_path ();
            init_upgrades ();
            load ();
            recalculate_stats ();
        }

        private void init_save_path () {
            // Check if running in Flatpak
            if (FileUtils.test ("/.flatpak-info", FileTest.EXISTS)) {
                string data_dir = Environment.get_user_data_dir ();
                string app_dir = Path.build_filename (data_dir, "vala-clicker");
                save_file_path = Path.build_filename (app_dir, "save.ini");
            } else {
                // Local development/run
                save_file_path = "save.ini";
            }
        }

        public string get_rank_title () {
            // 10 Distinct thematic levels/ranks
            if (level < 5) return "Mere Mortal";
            if (level < 10) return "Carpal Tunnel Initiate";
            if (level < 15) return "Kinetic Harvester";
            if (level < 20) return "Automation Baron";
            if (level < 30) return "Silicon Warlord";
            if (level < 40) return "Neural Architect";
            if (level < 50) return "Quantum Manipulator";
            if (level < 65) return "Dimensional Entity";
            if (level < 80) return "Multiverse Overlord";
            return "Reality Weaver";
        }

        public void save () {
            var file = new KeyFile ();
            file.set_double ("Player", "count", count);
            file.set_double ("Player", "total_clicks_ever", total_clicks_ever);
            file.set_integer ("Player", "level", level);
            file.set_double ("Player", "xp", xp);
            file.set_double ("Player", "xp_to_next_level", xp_to_next_level);

            foreach (var up in upgrades) {
                file.set_integer ("Upgrades", up.name, up.level);
            }

            try {
                string dirname = Path.get_dirname (save_file_path);
                if (dirname != "." && !FileUtils.test (dirname, FileTest.IS_DIR)) {
                    DirUtils.create_with_parents (dirname, 0755);
                }
                FileUtils.set_contents (save_file_path, file.to_data ());
            } catch (Error e) {
                stderr.printf ("Error saving game: %s\n", e.message);
            }
        }

        public void load () {
            if (!FileUtils.test (save_file_path, FileTest.EXISTS)) {
                return;
            }

            var file = new KeyFile ();
            try {
                file.load_from_file (save_file_path, KeyFileFlags.NONE);
                count = file.get_double ("Player", "count");
                total_clicks_ever = file.get_double ("Player", "total_clicks_ever");
                level = file.get_integer ("Player", "level");
                xp = file.get_double ("Player", "xp");
                xp_to_next_level = file.get_double ("Player", "xp_to_next_level");

                foreach (var up in upgrades) {
                    if (file.has_key ("Upgrades", up.name)) {
                        up.level = file.get_integer ("Upgrades", up.name);
                    }
                }
            } catch (Error e) {
                stderr.printf ("Error loading game: %s\n", e.message);
            }
        }

        private void init_upgrades () {
            // Tier 1: The Basics
            var sentient_cursor = new Upgrade ("Sentient Cursor", "A rogue cursor that clicks for you. (+1 CPS)", 15.0, 1.15, UpgradeType.AUTO_CLICK, 1.0);
            var ergonomic_keycap = new Upgrade ("Ergonomic Keycap", "Fingers don't hurt as much. (+1 Click Power)", 50.0, 1.5, UpgradeType.CLICK_MULTIPLIER, 1.0);
            
            // Tier 2: Biological Enhancement
            var caffeine_drip = new Upgrade ("Caffeine IV Drip", "Hyperactive clicking. (+5 CPS)", 200.0, 1.15, UpgradeType.AUTO_CLICK, 5.0, {
                new Requirement (sentient_cursor, 10)
            });
            var overclocked_switch = new Upgrade ("Overclocked Switch", "Mechanically superior hardware. (+5 Click Power)", 500.0, 1.5, UpgradeType.CLICK_MULTIPLIER, 5.0, {
                new Requirement (ergonomic_keycap, 5)
            });

            // Tier 3: Automation Era
            var bot_swarm = new Upgrade ("AI Click-Bot Swarm", "A neural net designed only to click. (+25 CPS)", 2500.0, 1.15, UpgradeType.AUTO_CLICK, 25.0, {
                new Requirement (caffeine_drip, 10)
            });
            var neural_interface = new Upgrade ("Neural Interface", "Think it, click it. (+20 Click Power)", 6000.0, 1.5, UpgradeType.CLICK_MULTIPLIER, 20.0, {
                new Requirement (overclocked_switch, 5)
            });

            // Tier 4: Quantum Physics
            var quantum_router = new Upgrade ("Quantum Click Router", "Entangled clicks across networks. (+100 CPS)", 20000.0, 1.15, UpgradeType.AUTO_CLICK, 100.0, {
                new Requirement (bot_swarm, 10)
            });
            var tachyon_mouse = new Upgrade ("Tachyon Mouse", "Clicks before you even move. (+100 Click Power)", 75000.0, 1.6, UpgradeType.CLICK_MULTIPLIER, 100.0, {
                new Requirement (neural_interface, 5)
            });

            // Tier 5: Reality Bending
            var spacetime_distort = new Upgrade ("Space-Time Distortion", "Bends time to fit more clicks. (CPS x1.2)", 200000.0, 2.0, UpgradeType.CPS_MULTIPLIER, 0.2, {
                new Requirement (quantum_router, 10)
            });
            var reality_matrix = new Upgrade ("Reality Bending Matrix", "Reality is just a click simulation. (+1000 CPS)", 1000000.0, 1.15, UpgradeType.AUTO_CLICK, 1000.0, {
                new Requirement (spacetime_distort, 1)
            });
            var multiversal_nexus = new Upgrade ("Multiversal Nexus", "Harnesses clicks from parallel universes. (CPS x1.5)", 15000000.0, 2.5, UpgradeType.CPS_MULTIPLIER, 0.5, {
                new Requirement (reality_matrix, 10)
            });

            upgrades = { 
                sentient_cursor, ergonomic_keycap, caffeine_drip, overclocked_switch, 
                bot_swarm, neural_interface, quantum_router, tachyon_mouse, 
                spacetime_distort, reality_matrix, multiversal_nexus 
            };
        }

        public void add_clicks (double val, bool manual = false) {
            double amount = val * global_multiplier;
            count += amount;
            total_clicks_ever += amount;
            
            // Gain XP: 20% of click value for manual, 5% for auto (makes active play highly rewarding)
            add_xp (amount * (manual ? 0.2 : 0.05));
            
            updated ();
        }

        private void add_xp (double val) {
            xp += val;
            while (xp >= xp_to_next_level) {
                xp -= xp_to_next_level;
                level++;
                xp_to_next_level *= 1.3; // Steeper curve, but offset by the lower base of 50
                
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
            double base_power = 1.0;
            double cps_mult = 1.0;

            // Level bonus: 2% global multiplier per level (Increased from 1%)
            global_multiplier = 1.0 + (level - 1) * 0.02;

            foreach (var up in upgrades) {
                if (up.level > 0) {
                    switch (up.upgrade_type) {
                        case UpgradeType.AUTO_CLICK:
                            base_cps += up.value * up.level;
                            break;
                        case UpgradeType.CLICK_MULTIPLIER:
                            base_power += up.value * up.level;
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
                xp_to_next_level = 50.0 * Math.pow (1.3, level - 1);
                recalculate_stats ();
            } else if (parts[0] == "reset") {
                count = 0;
                total_clicks_ever = 0;
                level = 1;
                xp = 0;
                xp_to_next_level = 50.0;
                foreach (var up in upgrades) up.level = 0;
                recalculate_stats ();
            }
            updated ();
        }
    }
}