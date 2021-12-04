#!/bin/bash


if [ -z $1 ]; then
	echo "Please enter the input file"
	exit
fi
##

if [ -e $1 ]; then
	echo "File exists"
else
	echo "File does not exit"
	exit
fi
##

if [ -f $1 ]; then
	echo "Valid file"
else
	echo "Invalid file"
	exit
fi
##

if [ -z $2 ]; then
	working_direcotry="."
else
	working_direcotry=$2
fi

input=$1

rm -r ../output_dir
mkdir ../output_dir
output_dir_path="$(realpath ../output_dir)"
root="$(realpath .)"
base_root="${root##*/}"
remove_from_root="${root%/*$base_root}"

cmd=$(head -n 1 "$input" | tail -n 1)
nol=$(head -n 2 "$input" | tail -n 1)
word_to_search=$(head -n 3 "$input" | tail -n 1)
touch ./../output.csv
echo "File path,Line Number,Line Containing Searched String" >> ./../output.csv
output_csv_path="$(realpath ../output.csv)"
number_of_files=0

    if [ $cmd = "begin" ]; then
    	cmd="head"
    else
    	cmd="tail"
    fi

traverse_directories() {
    cd "$1"

	for f in *
	do
		if [ -d "$f" ]; then
			# next level directory
			traverse_directories "$f"
		elif [ -f "$f" ]; then
			if file "$f" | grep -q text ; then
				# text file; need to process
				if $cmd -n $nol $f | grep -qi $word_to_search; then
					#current_dir=`echo "${PWD##*/}"`
					#current_dir=`echo ${realpath --relative-to="$remove_from_root" "${PWD}"}`
					#abs_current_dir="$(realpath .)"
					
					relative_directory="$(realpath --relative-to="$remove_from_root" .)"
					#relative_directory="${abs_current_dir%/$remove_from_root*}"
					#echo $relative_directory
					fn="${f%.*}"
					ext="${f##*.}"

					all_index=$($cmd -n $nol $f | grep -ni $word_to_search | cut -f1 -d':')
					echo $all_index

					if [ $cmd = "head" ]; then
						line_no=$($cmd -n $nol $f | grep -ni $word_to_search | cut -f1 -d':' | head -1)
					fi


					if [ $cmd = "tail" ]; then
						line_no=$($cmd -n $nol $f | grep -ni $word_to_search | cut -f1 -d':' | tail -1)
					fi

					#line_no=$($cmd -n $nol $f | grep -ni $word_to_search | cut -f1 -d':' )
					#echo $line_no
					line_no_addition=$line_no
					#new_file_name="${current_dir}.${fn}${line_no}.${ext}"
					total_lines=$(wc -l $f | cut -f1 -d' ')
					#echo $total_lines

					if [ $cmd = "tail" ]; then
						line_no_addition=`expr $total_lines - $nol`

						if [ $line_no_addition -lt 0 ]; then
							line_no_addition=0
						fi

						line_no_addition=`expr $line_no_addition + $line_no`
					fi

					for i in $all_index
					do
						idx=$i
						line_no_addition=$idx
						if [ $cmd = "tail" ]; then
							line_no_addition=`expr $total_lines - $nol`

							if [ $line_no_addition -lt 0 ]; then
								line_no_addition=0
							fi

							line_no_addition=`expr $line_no_addition + $idx`
						fi
						new_file_name="${relative_directory}/${fn}.${ext}"
						var1=`head -$line_no_addition $f | tail -1`
						echo "$new_file_name,$line_no_addition,$var1" >> "$output_csv_path"
					done

					new_file_name="${relative_directory}/${fn}${line_no_addition}.${ext}"
					#echo $new_file_name
					#echo $line_no_addition
					#var1=`head -$line_no_addition $f | tail -1`
					#echo "$new_file_name,$line_no_addition,$var1" >> "$output_csv_path"

					new_file_name=`echo $new_file_name | sed 's/\//\./g'`
					cp $f "${output_dir_path}/${new_file_name}"
					number_of_files=`expr $number_of_files + 1`
				fi
			else
				echo $f is a non text file
			fi
		fi
	done

	cd ../
}


traverse_directories . 
echo "total number of files: $number_of_files"