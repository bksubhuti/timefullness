cd my_time_schedule.AppDir

cp -r ~/git/my_time_schedule/build/linux/x64/release/bundle/* .

# Navigate back to the project root
cd ..


# Download the AppImage tool
#wget https://github.com/AppImage/AppImageKit/releases/download/13/appimagetool-x86_64.AppImage
#wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
#chmod +x appimagetool-x86_64.AppImage

#change the permissions of the app run file
chmod +x my_time_schedule.AppDir/AppRun
chmod +x my_time_schedule.AppDir/my_time_schedule

# Build the AppImage
#ARCH=x86_64 ./appimagetool-x86_64.AppImage my_time_schedule.AppDir/ my_time_schedule.AppImage
./appimagetool-x86_64.AppImage my_time_schedule.AppDir/ my_time_schedule.AppImage