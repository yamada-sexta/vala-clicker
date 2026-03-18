namespace Clicker {
    public enum UpgradeType {
        AUTO_CLICK,
        CLICK_MULTIPLIER
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
        public int base_cost { get; set; }
        public double cost_multiplier { get; set; }
        public UpgradeType upgrade_type { get; set; }
        public double value { get; set; }

        public int level { get; private set; default = 0; }
        public Requirement[] requirements;

        public Upgrade (string name, string description, int base_cost, double cost_multiplier, UpgradeType type, double value, Requirement[] requirements = {}) {
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

        public int get_current_cost () {
            return (int) (base_cost * Math.pow (cost_multiplier, level));
        }

        public void purchase () {
            level++;
        }

        public bool is_unlocked () {
            foreach (var req in requirements) {
                if (!req.is_met ()) {
                    return false;
                }
            }
            return true;
        }
    }
}
