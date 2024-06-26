#!/bin/bash

DOC_DIR="$(pwd)/doc"

check_requirement()
{
  ansible-doc --help &>/dev/null
  if [ $? -ne 0 ]; then
    echo "ansible-doc not available"
    exit
  fi
}

collect_info()
{
  # available_types="become connection"
  available_types=$(ansible-doc --help | head | grep "\-t " | cut -d"{" -f2 | cut -d"}" -f1 | sed -e "s/,/ /g" | sed -e 's/keyword//g')
  
  mkdir -pv $DOC_DIR
  
  for type in $available_types
  do
    echo "Preparing type $type"
    module_name=$(ansible-doc -t $type -l | awk '{print $1}') 
    for page in $module_name
    do
      #echo "- $page"
      echo "<pre>" > $DOC_DIR/$type-$page.html
      PAGER=cat ansible-doc -t $type $page >> $DOC_DIR/$type-$page.html
      echo "</pre>" >> $DOC_DIR/$type-$page.html
    done
  done
}


create_html_menu()
{
  echo "
<html>
  <frameset cols=\"30%, 70%\">
    <frame src=\"menu.html\" name=\"frame1\"/>
    <frame src=\"initial.html\" name=\"frame2\"/>
  </frameset>
</html>
  " >$DOC_DIR/index.html

  echo "
  <center>  
  <h1>Please, click on the module you would like more information on the left menu
  <br>

  <---
  </h1>
  </center>
  " >$DOC_DIR/initial.html

  echo "
  <!DOCTYPE html>
  <html>
  <head>
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
    <link rel=\"stylesheet\" href=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/css/bootstrap.min.css\">
    <script src=\"https://ajax.googleapis.com/ajax/libs/jquery/3.7.1/jquery.min.js\"></script>
    <script src=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.4.1/js/bootstrap.min.js\"></script>
    <style>
        .button {
            width: 200px;
        }
    </style>
  </head>
  <body>


    &nbsp;&nbsp;&nbsp;More info about this project?
    <br>
    &nbsp;&nbsp;&nbsp;<a href=\"https://github.com/waldirio/ansible-doc-html\" target=\"_blank\">click here!</a>
    <br>
    <br>

    <div class=\"container\">
  " >$DOC_DIR/menu.html
  # some code here v

  all_types_to_collapse_expand=$(ls $DOC_DIR | grep -E -v '(index.html|menu.html|initial.html)' | cut -d"-" -f1 | sort -u | sed -e 's/^/#/g' | tr '\n' ',' | sed 's/,$//g')

  echo "
        <button type=\"button\" class=\"btn btn-info button\" data-toggle=\"collapse\" data-target=\"$all_types_to_collapse_expand\">Expand All / Collapse All</button>
    </div>
  " >>$DOC_DIR/menu.html

  all_types=$(ls $DOC_DIR | grep -E -v '(index.html|menu.html|initial.html)' | cut -d"-" -f1 | sort -u)
  for current_type in $all_types
  do
    count=$(ls $DOC_DIR/${current_type}-* | wc -l | awk '{print $1}')
    echo "
    <div class=\"container\">
    <button type=\"button\" class=\"btn btn-info button\" data-toggle=\"collapse\" data-target=\"#$current_type\">$current_type - $count</button>
    <div id=\"$current_type\" class=\"collapse\">
    " >>$DOC_DIR/menu.html
  
      for items in $(ls -1 doc/* | grep "$current_type\-" | sort -u)
      do
        html_file_name=$(echo $items | cut -d"-" -f2)
        ansible_module_full_name=$(echo $items | cut -d"-" -f2 | sed 's/.html//g')
        echo "<a href=\"${current_type}-${html_file_name}\" target=\"frame2\">$ansible_module_full_name</a></br>" >>$DOC_DIR/menu.html
      done
  
    echo "
    </div>
    </div>
    " >>$DOC_DIR/menu.html
  done
  
  # some code here ^
  echo "
  </body>
  </html>
  " >>$DOC_DIR/menu.html
}

check_requirement
collect_info
create_html_menu
