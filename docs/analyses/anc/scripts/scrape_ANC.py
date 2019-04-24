
# coding: utf-8

# In[1]:


import requests
import pandas as pd


# In[3]:


dfs = []
base_url = "https://anc.dc.gov/page/advisory-neighborhood-commission-"
for i in range(1, 9):
    for j in ['a', 'b', 'c', 'd', 'e', 'f', 'g']:
        url = base_url + str(i) + j
        r = requests.get(url)
        if r.status_code == 200:
            df = pd.read_html(r.content, header=None, converters={'SMD': str})
            dfs.append(df[0])


# In[4]:


#missing one ANC, 1B due to a 403 error
r = requests.get("https://anc.dc.gov/page/advisory-neighborhood-commission-1b-00")


# In[5]:


df = pd.read_html(r.content, header=None)
dfs.append(df[0])


# In[6]:


len(dfs) == 40


# In[12]:


current_members = pd.concat(dfs, sort=False)


# In[18]:


current_members = current_members.set_index('SMD', verify_integrity= True)


# In[14]:


current_members.shape


# In[19]:


current_members.to_csv("../cleaned_data/current_anc_membership.csv")


# In[20]:


current_members.head()

