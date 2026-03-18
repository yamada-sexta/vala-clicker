namespace Clicker {
    public class NumberFormatter : Object {
        public static const string[] suffixes = {
            "", "k", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "De",
            "UnD", "DuD", "TrD", "QaD", "QiD", "SxD", "SpD", "OcD", "NoD", "Vi"
        };

        public static string format (double val) {
            if (val < 0) return "-" + format (-val);
            if (val == 0) return "0";
            if (val < 1000.0) {
                return "%.1f".printf (val).replace (".0", "");
            }

            double temp = val;
            int exp = 0;
            while (temp >= 1000.0 && exp < suffixes.length - 1) {
                temp /= 1000.0;
                exp++;
            }

            if (temp >= 1000.0) {
                return "%.2e".printf (val);
            }

            return "%.2f%s".printf (temp, suffixes[exp]);
        }
    }
}
