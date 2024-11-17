# TODO: Set these paths and log out and in, then run the "backup" alias (see bottom)
ARCHIVE_PATH="/PATH/TO/ARCHIVES"
BACKUP_PATH="/PATH/TO/BACKUPS"
BACKUP_TARGETS=(
  "/PATH/TO/TARGET/FILE.txt"
  "/PATH/TO/TARGET/FOLDER"
)

ignore_math_errors() { return 0; }

# font
red="\e[1;31m"
yellow="\e[1;33m"
green="\e[1;32m"
white="\e[0m"

# time
current_date=$(date +%s) 
one_day=86400 # 60s * 60m * 24h
warning_age=$((${one_day}*7)) || ignore_math_errors
safe_age=$((${one_day}*3))    || ignore_math_errors

# motd
last_archive=$(ls --sort=time "${ARCHIVE_PATH}" | head --lines=1)
last_archive_date=$(date --reference="${ARCHIVE_PATH}/${last_archive}" +%s)
last_archive_date_title=$(date --reference="${ARCHIVE_PATH}/${last_archive}" +"%B %d, %Y")
last_archive_age=$((current_date - last_archive_date)) || ignore_math_errors
last_archive_age_hours=$((last_archive_age/60/60))     || ignore_math_errors
notification_color="${red}"
(( last_archive_age < warning_age )) && notification_color="${yellow}"
(( last_archive_age < safe_age ))    && notification_color="${green}"

create_archive_snapshot() {
  archive_filename="Backups_$(date +%Y-%m-%d_%H-%M-%S).tar"
  [[ -f "${ARCHIVE_PATH}/${archive_filename}" ]] && { echo "Archiving collision.  Try again or check clock."; return 1; }
  tar --create --gzip --file "${ARCHIVE_PATH}/${archive_filename}" "${BACKUP_PATH}"
}

sync_backup_targets() {
  for target in "${BACKUP_TARGETS[@]}"; do
    rsync --archive --itemize-changes --info=progress2 "${target}" "${BACKUP_PATH}"
  done
}

echo ""
echo -e "Last backup was on ${last_archive_date_title} (${notification_color}${last_archive_age_hours}${white} hours ago)"
echo ""

unset red yellow green white current_date one_day warning_age safe_age last_archive last_archive_date last_archive_date_title last_archive_age last_archive_age_hours notification_color 

alias backup="create_archive_snapshot && sync_backup_targets" # archive all current backups, then sync them
