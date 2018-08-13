# write video to different frames
from moviepy.editor import VideoFileClip
from RZutilpy.system import rzpath,makedirs


# the file name you want to change
video_file = 'Interstellar - Ending Scene 1080p HD.mp4'


video_folder = '/Users/ruyuan/Documents/Code_git/samplevideo/'
video_file_full = rzpath(video_folder + video_file)
makedirs(video_file_full.strnosuffix)
imagesequence_folder = rzpath(video_file_full.strnosuffix)

# create the videoclip
clip = VideoFileClip(video_file_full.str)

# write image sequences
clip.write_images_sequence((imagesequence_folder/'frame%04d.png').str, verbose=True, progress_bar=True)