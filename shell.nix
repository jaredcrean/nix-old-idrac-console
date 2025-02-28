{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    openjdk8
    adoptopenjdk-icedtea-web
    wget
    curl
    zenity  # Now correctly referenced at top level
  ];

  shellHook = ''
    echo "===== iDRAC Java Console Environment ====="
    echo "Java Version:"
    java -version
    
    # Proper environment variables
    export JAVA_HOME=${pkgs.openjdk8}/lib/openjdk
    export PATH="$JAVA_HOME/bin:$PATH"
    
    # Java Web Start settings
    export _JAVA_OPTIONS="-Djava.util.prefs.userRoot=$HOME/.java/prefs"
    export JAVA_TOOL_OPTIONS="-Djavaws.cfg.jauthenticator=true -Djava.security.policy=java.policy"
    
    # Create a less restrictive Java policy file if it doesn't exist
    if [ ! -f java.policy ]; then
      cat > java.policy << 'EOL'
grant {
  permission java.security.AllPermission;
};
EOL
      echo "Created java.policy file for less restrictive security"
    fi
    
    # Configure Java security for older servers
    JAVA_SECURITY_PATH="$JAVA_HOME/lib/security/java.security"
    if [ -f "$JAVA_SECURITY_PATH" ]; then
      # Back up original if no backup exists
      if [ ! -f "$JAVA_SECURITY_PATH.backup" ]; then
        cp "$JAVA_SECURITY_PATH" "$JAVA_SECURITY_PATH.backup"
      fi
      
      # Lower security settings for iDRAC compatibility
      mkdir -p ~/.config/icedtea-web
      echo "deployment.security.level=MEDIUM" > ~/.config/icedtea-web/deployment.properties
      echo "deployment.security.notinca.warning=false" >> ~/.config/icedtea-web/deployment.properties
    fi
    
    echo ""
    echo "iDRAC Java Console Launch Instructions:"
    echo "1. Ensure network access to iDRAC"
    echo "2. Launch with: javaws https://<iDRAC_IP>/software/launch.jnlp"
    echo "3. If needed, you can add exceptions with: javaws -viewer"
    echo "====================================="
    
    # Helpful function to launch iDRAC console
    idrac-console() {
      if [ -z "$1" ]; then
        echo "Usage: idrac-console <iDRAC_IP>"
        return 1
      fi
      
      echo "Launching iDRAC console for $1..."
      javaws "https://$1/software/launch.jnlp"
    }
  '';
}
