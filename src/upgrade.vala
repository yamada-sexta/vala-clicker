namespace Clicker {
    public enum UpgradeType {
        AUTO_CLICK,
        CLICK_MULTIPLIER
    }

    public class Upgrade : Object {
        public string name { get; construct; }
        public string description { get; construct; }
        public int base_cost { get; construct; }
        public double cost_multiplier { get; construct; }
        public UpgradeType upgrade_type { get; construct; }
        public double value { get; construct; }

        public int level { get; private set; default = 0; }

        public Upgrade (string name, string description, int base_cost, double cost_multiplier, UpgradeType type, double value) {
            Object (
                name: name,
                description: description,
                base_cost: base_cost,
                cost_multiplier: cost_multiplier,
                upgrade_type: type,
                value: value
            );
        }

        public int get_current_cost () {
            return (int) (base_cost * Math.pow (cost_multiplier, level));
        }

        public void purchase () {
            level++;
        }
    }
}
