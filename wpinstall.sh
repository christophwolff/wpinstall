#!/bin/bash -e

wpuser='admin'

clear

echo "================================================================="
echo "BR WordPress Installer"
echo "Based on Christopher Geary's wpinstall (https://goo.gl/zmC9mH)"
echo "================================================================="

# accept user input for the databse name
echo "Database Name: "
read -e dbname

# accept the name of our website
echo "Site Name: "
read -e sitename

# accept the name of our website
echo "TLD: "
read -e topleveldomain

# accept a comma separated list of pages
echo "Add Pages: "
read -e allpages

# accept the name of our website
echo "Locale? (i.e. 'de_DE'): "
read -e locale

# Licence Key to download latest acf
echo "ACF Key: "
read -e acfkey

# add a simple yes/no confirmation before we proceed
echo "Run Install? (y/n)"
read -e run

# if the user didn't say no, then go ahead an install
if [ "$run" == n ] ; then
exit
else


# download the WordPress core files
wp core download --locale=$locale

wp core language install $locale
wp core language activate $locale

# create the wp-config file with our standard setup
wp core config --dbname=$dbname --dbuser=root --dbpass= --extra-php <<PHP
define( 'WP_DEBUG', true );
define( 'DISALLOW_FILE_EDIT', true );
PHP

# parse the current directory name
currentdirectory=${PWD##*/}

# generate random 12 character password
# password=$(LC_CTYPE=C tr -dc A-Za-z0-9_\!\@\#\$\%\^\&\*\(\)-+= < /dev/urandom | head -c 12)
password="admin"
# copy password to clipboard
echo $password | pbcopy

# create database, and install WordPress
wp db create
wp core install --url="https://$currentdirectory.$topleveldomain" --title="$sitename" --admin_user="$wpuser" --admin_password="$password" --admin_email="user@example.org"

# discourage search engines
wp option update blog_public 0

# show only 6 posts on an archive page
#wp option update posts_per_page 6

# delete sample page, and create homepage
wp post delete $(wp post list --post_type=page --posts_per_page=1 --post_status=publish --pagename="Beispiel-Seite" --field=ID --format=ids)
wp post create --post_type=page --post_title=Home --post_status=publish --post_author=$(wp user get $wpuser --field=ID --format=ids)

# set homepage as front page
wp option update show_on_front 'page'

# set homepage to be the new page
wp option update page_on_front $(wp post list --post_type=page --post_status=publish --posts_per_page=1 --pagename=home --field=ID --format=ids)

# create all of the pages
export IFS=","
for page in $allpages; do
	wp post create --post_type=page --post_status=publish --post_author=$(wp user get $wpuser --field=ID --format=ids) --post_title="$(echo $page | sed -e 's/^ *//' -e 's/ *$//')"
done

# set pretty urls
wp rewrite structure '/%postname%/' --hard
wp rewrite flush --hard

# delete akismet and hello dolly
wp plugin delete akismet
wp plugin delete hello

# install lt-tables plugin
# wp plugin install https://github.com/ltconsulting/lt-tables/archive/master.zip --activate

# # install antispam plugin
# wp plugin install antispam-bee --activate
wp plugin install https://connect.advancedcustomfields.com/index.php\?p\=pro\&a\=download\&k\=$acfkey
wp plugin activate advanced-custom-fields-pro

cd wp-content/themes
git clone git@github.com:digitalegarage/br-wordpress-boilerplate-theme.git
cd br-wordpress-boilerplate-theme
rm -rf .git
yarn
yarn run dev
wp theme activate br-wordpress-boilerplate-theme
cd ..
cd ..
cd ..
# # install the company starter theme
# wp theme install ~/Documents/lt-theme.zip --activate

clear

# create a navigation bar
wp menu create "Main Navigation"

# add pages to navigation
export IFS=" "
for pageid in $(wp post list --order="ASC" --orderby="date" --post_type=page --post_status=publish --posts_per_page=-1 --field=ID --format=ids); do
	wp menu item add-post main-navigation $pageid
done

# assign navigaiton to primary location
wp menu location assign main-navigation primary

clear

# Local SSL for valet
valet secure

echo "================================================================="
echo "Installation is complete. Your username/password is listed below."
echo ""
echo "Username: $wpuser"
echo "Password: $password"
echo ""
echo "================================================================="

# Open the new website with Google Chrome
/usr/bin/open -a "/Applications/Google Chrome.app" "https://$currentdirectory.$topleveldomain/wp-login.php"

# Open the project in TextMate
# /Applications/TextMate.app/Contents/Resources/mate ~/$currentdirectory/wp-content/themes/

fi