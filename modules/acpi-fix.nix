{ pkgs, ... }:

# Fix for ASUS firmware bug: the DSDT shipped on this Vivobook never defines a
# number of symbols that the DptfTabl SSDT (SSDT1) references. At boot the ACPI
# interpreter aborts those methods with AE_NOT_FOUND ("ACPI BIOS Error (bug):
# Could not resolve symbol [\CTDP] / [\_SB...SENx._CRT.SxCT] ...").
#
# We ship a tiny SSDT that *defines only the genuinely missing* symbols. Some
# symbols the DptfTabl table references (e.g. SADE, SxS3, SxDE) DO already exist
# in the DSDT; declaring them again makes the kernel reject the whole override
# with AE_ALREADY_EXISTS, so they must be left out.
#
# The kernel's ACPI initrd loader reads the initramfs cpio directly and *before*
# it is unpacked, so the table must live in a separate UNCOMPRESSED cpio
# prepended to the initrd (not inside the compressed stage-1 cpio). The values
# are safe thermal trip points (degrees Celsius) so DPTF/int340x thermal
# management works instead of erroring.
let
  ssdt = pkgs.runCommand "ssdt-dptf-fix.aml" {
    nativeBuildInputs = [ pkgs.acpica-tools ];
  } ''
    cat > src.dsl <<'ASL'
    DefinitionBlock ("ssdt-dptf-fix.aml", "SSDT", 2, "OEMFIX", "DPTFFIX", 0x00000001)
    {
        Name (CTDP, 0)
        Name (SSP1, 0x0A)
        Name (SSP2, 0x0A)
        Name (SSP3, 0x0A)
        Name (SSP4, 0x0A)
        Name (SSP5, 0x0A)

        Name (S1CT, 100)
        Name (S1HT, 95)
        Name (S1PT, 90)
        Name (S1AT, 80)
        Name (S2CT, 100)
        Name (S2HT, 95)
        Name (S2PT, 90)
        Name (S2AT, 80)
        Name (S3CT, 100)
        Name (S3HT, 95)
        Name (S3PT, 90)
        Name (S3AT, 80)
        Name (S4CT, 100)
        Name (S4HT, 95)
        Name (S4PT, 90)
        Name (S4AT, 80)
        Name (S5CT, 100)
        Name (S5HT, 95)
        Name (S5PT, 90)
        Name (S5AT, 80)
    }
    ASL
    iasl -ve src.dsl
    cp ssdt-dptf-fix.aml "$out"
  '';

  # Build an uncompressed (newc) cpio at kernel/firmware/acpi/<name>.aml so the
  # kernel's ACPI initrd loader can pick it up.
  ssdtCpio = pkgs.runCommand "ssdt-dptf-fix.cpio" {
    nativeBuildInputs = [ pkgs.cpio ];
  } ''
    mkdir -p root/kernel/firmware/acpi
    cp ${ssdt} root/kernel/firmware/acpi/dptf.aml
    (cd root && find . -print0 | sort -z | cpio --quiet -o -H newc -R +0:+0 --reproducible --null) > "$out"
  '';
in {
  # Prepend the uncompressed cpio to the initrd (works for both the legacy and
  # the systemd-based stage-1 initrd).
  boot.initrd.prepend = [ "${ssdtCpio}" ];
}
