

# Function to display usage information
usage() {
  echo "Usage: $0 <starting_index>"
  echo "  <starting_index>  The starting index for renaming directories (00 to 99)."
  exit 1
}

# Check if a starting index is provided
if [ -z "$1" ]; then
  usage
fi

# Get the starting index from the first argument
start_index=$1

# Validate the starting index
if ! [[ $start_index =~ ^[0-9]{2}$ ]]; then
  echo "Error: Starting index must be a two-digit number (00 to 99)."
  exit 1
fi

# Initialize an array to hold the changes
declare -a changes

# Initialize a counter for the new index
new_index=$((10#$start_index + 1))

# Loop through all directories matching the pattern
for dir in [0-9][0-9]-*; do
  # Extract the numeric part and the rest of the name
  num=${dir%%-*}
  rest=${dir#*-}
  
  # Only rename if the numeric part is greater than or equal to the starting index
  if (( 10#$num >= 10#$start_index )); then
    # Form the new directory name with the new index
    new_num=$(printf "%02d" $new_index)
    new_dir="${new_num}-${rest}"
    
    # Add the change to the array if the new name is different
    if [[ "$dir" != "$new_dir" ]]; then
      changes+=("$dir -> $new_dir")
    fi
    
    # Increment the new index and wrap around if it exceeds 99
    new_index=$(( (new_index + 1) % 100 ))
  fi
done

# Display the list of changes
echo "The following changes will be made:"
for change in "${changes[@]}"; do
  echo "$change"
done

# Ask for confirmation
echo "Do you want to proceed with these changes? (y/n)"
read -r response
if [[ "$response" == "y" ]]; then
  # Apply the changes
  new_index=$((10#$start_index + 1))
  for dir in [0-9][0-9]-*; do
    num=${dir%%-*}
    rest=${dir#*-}
    if (( 10#$num >= 10#$start_index )); then
      new_num=$(printf "%02d" $new_index)
      new_dir="${new_num}-${rest}"
      if [[ "$dir" != "$new_dir" ]]; then
        mv "$dir" "$new_dir"
      fi
      new_index=$(( (new_index + 1) % 100 ))
    fi
  done
  echo "Changes applied."
else
  echo "No changes made."
fi
