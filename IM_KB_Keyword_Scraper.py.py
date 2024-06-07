import requests
from bs4 import BeautifulSoup

#base URL for articles
base_url = 'https://kb.cloud.im'

#function to parse page contents

def parser(url):
    html = requests.get(url)
    soup = BeautifulSoup(html.content, 'html.parser')
    return soup

#parse folder for links to tables and save table links in an array

folder_url = 'https://kb.cloud.im/support/solutions/folders/66000425327'

table_links_array = [folder_url]

folder_page_contents = parser(folder_url)

pagination = folder_page_contents.find(class_='pagination')

find_table_links = pagination.find_all('a')

for table_links in find_table_links[2:len(find_table_links)]:

    table_links_array.append(base_url + table_links['href'])


#parse table links for links to individual articles and save the article links in an array
article_links = []

for table_page in table_links_array:

    table_page_contents = parser(table_page)

    article_class_selector = table_page_contents.find(class_='article-list c-list')

    article_link_selector = article_class_selector.find_all('a', class_='c-link')

    for article_link in article_link_selector:
        article_links.append(base_url + str(article_link['href']))


#parse article links for key prases 
links_to_investigate = []

phrases_to_find = ['relationship']

for final_link in article_links:

    article_page_content = parser(final_link)

    article_page_text = article_page_content.get_text()

    if any(phrase in article_page_text for phrase in phrases_to_find):
            links_to_investigate.append(final_link)

for check_me_out in links_to_investigate:
     print(check_me_out)
